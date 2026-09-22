/// A slice of a file, for a stream that keeps its pieces inside one file.
class ByteRange {
  const ByteRange(this.offset, this.length);

  final int offset;
  final int length;

  int get last => offset + length - 1;
}
