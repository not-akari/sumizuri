package com.sumizuri.app.data.db

import androidx.room3.AutoMigration
import androidx.room3.ConstructedBy
import androidx.room3.Database
import androidx.room3.RoomDatabase
import androidx.room3.RoomDatabaseConstructor
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import com.sumizuri.app.data.db.category.CategoryDao
import com.sumizuri.app.data.db.category.CategoryEntity
import com.sumizuri.app.data.db.category.TitleCategoryEntity
import com.sumizuri.app.data.db.chapter.ChapterDao
import com.sumizuri.app.data.db.chapter.ChapterEntity
import com.sumizuri.app.data.db.cookie.CookieDao
import com.sumizuri.app.data.db.cookie.CookieEntity
import com.sumizuri.app.data.db.download.DownloadDao
import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.db.tracker.TrackerLinkDao
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.db.log.LogDao
import com.sumizuri.app.data.db.log.LogRow
import com.sumizuri.app.data.db.progress.ProgressDao
import com.sumizuri.app.data.db.progress.ProgressEntity
import com.sumizuri.app.data.db.repo.RepoDao
import com.sumizuri.app.data.db.repo.RepoEntity
import com.sumizuri.app.data.db.setting.SettingDao
import com.sumizuri.app.data.db.setting.SettingEntity
import com.sumizuri.app.data.db.source.SourceDao
import com.sumizuri.app.data.db.source.SourceEntity
import com.sumizuri.app.data.db.title.TitleDao
import com.sumizuri.app.data.db.title.TitleEntity
import com.sumizuri.app.data.db.value.SourceValueDao
import com.sumizuri.app.data.db.value.SourceValueEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO

// When a table changes, raise the version, export the new schema and add a migration.
@Database(
    entities = [TitleEntity::class, ChapterEntity::class, ProgressEntity::class, SettingEntity::class, SourceEntity::class, SourceValueEntity::class, CookieEntity::class, LogRow::class, RepoEntity::class, CategoryEntity::class, TitleCategoryEntity::class, DownloadEntity::class, TrackerLinkEntity::class],
    version = 20,
    autoMigrations = [
        AutoMigration(from = 1, to = 2),
        AutoMigration(from = 2, to = 3),
        AutoMigration(from = 3, to = 4),
        AutoMigration(from = 4, to = 5),
        AutoMigration(from = 5, to = 6),
        AutoMigration(from = 6, to = 7),
        AutoMigration(from = 7, to = 8),
        AutoMigration(from = 8, to = 9),
        AutoMigration(from = 9, to = 10),
        AutoMigration(from = 10, to = 11),
        AutoMigration(from = 11, to = 12),
        AutoMigration(from = 12, to = 13),
        AutoMigration(from = 13, to = 14),
        AutoMigration(from = 14, to = 15),
        AutoMigration(from = 15, to = 16),
        AutoMigration(from = 16, to = 17),
        AutoMigration(from = 17, to = 18),
        AutoMigration(from = 18, to = 19),
        AutoMigration(from = 19, to = 20),
    ],
)
@ConstructedBy(AppDatabaseConstructor::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun titles(): TitleDao
    abstract fun chapters(): ChapterDao
    abstract fun progress(): ProgressDao
    abstract fun settings(): SettingDao
    abstract fun sources(): SourceDao
    abstract fun values(): SourceValueDao
    abstract fun cookies(): CookieDao
    abstract fun logs(): LogDao
    abstract fun repos(): RepoDao
    abstract fun categories(): CategoryDao
    abstract fun downloads(): DownloadDao
    abstract fun trackerLinks(): TrackerLinkDao
}

// Room writes the platform versions of this itself.
@Suppress("KotlinNoActualForExpect")
expect object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    override fun initialize(): AppDatabase
}

fun buildDatabase(builder: RoomDatabase.Builder<AppDatabase>): AppDatabase = builder
    .setDriver(BundledSQLiteDriver())
    .setQueryCoroutineContext(Dispatchers.IO)
    .build()
