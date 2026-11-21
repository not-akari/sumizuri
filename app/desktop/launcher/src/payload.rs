// The app packed at the end of this file: zstd chunks, a list of the files, and a footer that says where the list is.

use ruzstd::decoding::FrameDecoder;
use std::fs::{self, File};
use std::io;
use std::os::windows::fs::FileExt;
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Mutex;
use std::thread;
use std::time::{Duration, UNIX_EPOCH};

// The last bytes of a setup: this mark, then where the list starts and how long it is.
const MARK: &[u8; 8] = b"SMZSETUP";
const FOOTER: u64 = 24;

// The files the setup window needs come out first, and the rest behind the open window. The files only the setup uses, such as its class archive, go to a folder of their own that is never installed.
pub const FIRST: u8 = 0;
pub const LATER: u8 = 1;
pub const SETUP: u8 = 2;

pub struct Chunk {
    offset: u64,
    packed: u32,
    raw: u32,
}

pub struct Entry {
    group: u8,
    path: String,
    size: u64,
    // When the file was last changed, in steps of 100 nanoseconds, which Java checks before it uses the class archive.
    modified: u64,
    chunks: Vec<Chunk>,
}

// Reads exactly the bytes asked for at a place in a file, as a read may give fewer.
fn read_at(file: &File, mut buf: &mut [u8], mut offset: u64) -> io::Result<()> {
    while !buf.is_empty() {
        let read = file.seek_read(buf, offset)?;
        if read == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "the setup file is cut short"));
        }
        buf = &mut buf[read..];
        offset += read as u64;
    }
    Ok(())
}

fn write_at(file: &File, mut buf: &[u8], mut offset: u64) -> io::Result<()> {
    while !buf.is_empty() {
        let written = file.seek_write(buf, offset)?;
        buf = &buf[written..];
        offset += written as u64;
    }
    Ok(())
}

// A small reader over the bytes of the list.
struct Cursor<'a>(&'a [u8]);

impl Cursor<'_> {
    fn take(&mut self, n: usize) -> io::Result<&[u8]> {
        if self.0.len() < n {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "the list of files is broken"));
        }
        let (head, rest) = self.0.split_at(n);
        self.0 = rest;
        Ok(head)
    }
    fn u8(&mut self) -> io::Result<u8> {
        Ok(self.take(1)?[0])
    }
    fn u16(&mut self) -> io::Result<u16> {
        Ok(u16::from_le_bytes(self.take(2)?.try_into().unwrap()))
    }
    fn u32(&mut self) -> io::Result<u32> {
        Ok(u32::from_le_bytes(self.take(4)?.try_into().unwrap()))
    }
    fn u64(&mut self) -> io::Result<u64> {
        Ok(u64::from_le_bytes(self.take(8)?.try_into().unwrap()))
    }
}

// The list of the packed files, read from the end of this file.
pub fn read_list(exe: &File) -> io::Result<Vec<Entry>> {
    let length = exe.metadata()?.len();
    if length < FOOTER {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "the setup file has no app in it"));
    }
    let mut footer = [0u8; FOOTER as usize];
    read_at(exe, &mut footer, length - FOOTER)?;
    if &footer[..8] != MARK {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "the setup file has no app in it"));
    }
    let start = u64::from_le_bytes(footer[8..16].try_into().unwrap());
    let size = u64::from_le_bytes(footer[16..24].try_into().unwrap());
    let mut bytes = vec![0u8; size as usize];
    read_at(exe, &mut bytes, start)?;
    let mut cursor = Cursor(&bytes);
    let count = cursor.u32()?;
    let mut entries = Vec::with_capacity(count as usize);
    for _ in 0..count {
        let group = cursor.u8()?;
        let name = cursor.u16()? as usize;
        let path = String::from_utf8(cursor.take(name)?.to_vec())
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "a file name is broken"))?;
        let size = cursor.u64()?;
        let modified = cursor.u64()?;
        let chunks = (0..cursor.u32()?)
            .map(|_| Ok(Chunk { offset: cursor.u64()?, packed: cursor.u32()?, raw: cursor.u32()? }))
            .collect::<io::Result<Vec<_>>>()?;
        entries.push(Entry { group, path, size, modified, chunks });
    }
    Ok(entries)
}

// Unpacks the files of the groups given, each into its folder, the chunks spread over every core, and gives each file back the time it was last changed. A chunk zstd could not make smaller is stored plain, with the same size packed and raw.
pub fn unpack(exe: &File, entries: &[Entry], targets: &[(u8, &Path)]) -> io::Result<()> {
    let mut files = Vec::new();
    for entry in entries {
        let Some((_, root)) = targets.iter().find(|(group, _)| *group == entry.group) else { continue };
        let target = root.join(&entry.path);
        if let Some(parent) = target.parent() {
            fs::create_dir_all(parent)?;
        }
        let file = File::create(&target)?;
        file.set_len(entry.size)?;
        files.push((entry, file, target));
    }
    let mut jobs = Vec::new();
    for (index, (entry, _, _)) in files.iter().enumerate() {
        let mut at = 0u64;
        for chunk in &entry.chunks {
            jobs.push((index, at, chunk));
            at += chunk.raw as u64;
        }
    }
    // The biggest chunks go first, so no core is left with a big one at the end.
    jobs.sort_by(|a, b| b.2.packed.cmp(&a.2.packed));
    let next = AtomicUsize::new(0);
    let failure = Mutex::new(None);
    let cores = thread::available_parallelism().map_or(4, |it| it.get()).min(16);
    thread::scope(|scope| {
        for _ in 0..cores {
            scope.spawn(|| {
                let mut decoder = FrameDecoder::new();
                let mut packed = Vec::new();
                let mut raw = Vec::new();
                loop {
                    let i = next.fetch_add(1, Ordering::Relaxed);
                    let Some(&(index, at, chunk)) = jobs.get(i) else { break };
                    let result = (|| {
                        packed.resize(chunk.packed as usize, 0);
                        read_at(exe, &mut packed, chunk.offset)?;
                        let data = if chunk.packed == chunk.raw {
                            &packed[..]
                        } else {
                            raw.resize(chunk.raw as usize, 0);
                            let made = decoder
                                .decode_all(&packed, &mut raw)
                                .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e.to_string()))?;
                            if made != raw.len() {
                                return Err(io::Error::new(io::ErrorKind::InvalidData, "a part of the app is broken"));
                            }
                            &raw[..]
                        };
                        write_at(&files[index].1, data, at)
                    })();
                    if let Err(error) = result {
                        failure.lock().unwrap().get_or_insert(error);
                        next.store(jobs.len(), Ordering::Relaxed);
                        break;
                    }
                }
            });
        }
    });
    if let Some(error) = failure.into_inner().unwrap() {
        return Err(error);
    }
    // Windows can stamp a file again when the handle that wrote it closes, so the time is set through a fresh handle once all are closed.
    let stamps: Vec<_> = files.into_iter().map(|(entry, file, path)| {
        drop(file);
        (entry.modified, path)
    }).collect();
    for (modified, path) in stamps {
        File::options().write(true).open(&path)?.set_modified(UNIX_EPOCH + Duration::from_nanos(modified * 100))?;
    }
    Ok(())
}
