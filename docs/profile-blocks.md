---
title: Profile block scripts
description: Change the blocks of the Sumizuri profile page, and write your own with formulas.
eyebrow: Guide for tinkerers
lead: Move, size and share the blocks of your profile page, or write your own with formulas and charts.
facts:
  - JSON scripts
  - Formulas
  - Charts
---

The profile page is made of blocks. Each block is a short **JSON script**: some values worked out with formulas, and a view that shows them. You can move, resize, add, remove and share blocks, and write your own.

## 1. Editing the profile

1. On the **Profile** tab, tap the blocks button at the top right, beside the settings. The **Edit blocks** page opens with your blocks as a list. On a wide screen, the page itself shows beside the list as it will look. On a phone, a **Preview** row above the list folds the page out, and changes show in it at once.
2. Drag a block by its handle (⠿) to put it somewhere else in the order. The page reads in this order, left to right and down.
3. On a phone, tap a block to pick it, and the bar at the top shows its icons. On a wide screen they sit on each line. The **size** icon, a picture of its shape, opens the **Size** sheet (see below). The others **edit** the block, **duplicate** it, **share** it by copying it as text, and **remove** it, which asks first. A part of the profile as it came only moves and goes.
4. **Add block** opens a gallery. See [Adding a block](#adding-a-block).
5. The **layouts** button, at the top right of the profile and of Edit blocks, offers four whole pages to start from: Classic, Dashboard, Minimal and Reader. A layout replaces your blocks, so copy any you made first. **Classic** puts the page back as it came.

### Sizes of a block

The page is four columns wide. The **Size** sheet sets two things, and each tap changes the block at once:

- **Width**, from 1 to 4 columns. A width smaller than the block needs is greyed out.
- **Height**, either **As tall as its content**, or a number of rows, which you change with the minus and plus buttons, up to 6. A row is a fixed height, and a block with a number of rows keeps it. A block as tall as its content grows or shrinks with what it shows.

No block goes smaller than what it shows needs. See [Sizes](#sizes).

### Adding a block

The **Add block** sheet has two tabs.

- **Blocks** is a gallery. Each card shows a small picture of the block, worked out from your own reading, with its name and the size it starts at. Tap a card to add it. The cards are the starter blocks, and under them the parts of the profile as it came (key figures, year of reading, continue reading, statistics). The picture is drawn smaller than life, and a tall block shows only its top.
- **Paste** takes a block someone shared as text. Paste it and tap **Add**. If it is not a block, the box says so.

### Editing a block

The pencil on a block opens **Edit block**. It shows the block as the profile will show it, as wide and as tall as it is on the page, on the four columns, with its size written under it. It changes as you edit. It has two editors:

- **Simple**: tap to choose what the block shows (a number, ring, bar, chart, list, covers, heatmap, text or a profile section), where its data comes from (a value of your reading, or what to count, by what, over how many days, and how many of the biggest to keep), the chart style, the colour, and the title and label. Starter blocks open here. Nothing to type but labels.
- **Script**: the JSON script described below, for anything the simple editor can't do. A block changed by hand here no longer opens in Simple, which then offers to start it over.

In **Script**, a toolbar over the text has **undo**, **redo**, **tidy** and **copy**. Undo takes back a word at a time. A line under the text says that the script is valid JSON, or where the first mistake is, with its line and column. Tap it to put the cursor there. A guide has pieces that go into the script with a tap. On a wide screen it sits beside the script, and on a phone it is behind the book button at the top.

On a phone, the page has two tabs, **Script** and **Preview**, each with the whole screen.

## 2. The shape of a script

```json
{
  "title": "Monthly goal",
  "let": {
    "goal": 60,
    "left": "max(goal - stats.month, 0)"
  },
  "view": { "ring": "stats.month", "max": "goal", "label": "{left} to go" }
}
```

| Key | What it is |
| --- | --- |
| `title` | Shown at the top of the block's card. Optional. |
| `let` | Named values, worked out in order, so a value can use the ones above it. A value is a formula in quotes, a number, or `true` or `false`. |
| `view` | What the block shows. See [Views](#6-views). |

Any text the script shows, such as a `title`, `label` or `caption`, can hold formulas in braces: `"{done} of {goal}"`.

## 3. Data

| Name | What it is |
| --- | --- |
| `stats.read` | Chapters read in all |
| `stats.today`, `stats.week`, `stats.month` | Chapters read today, in the last 7 days, in the last 30 days |
| `stats.streak`, `stats.best` | Current and longest streak of days with reading |
| `stats.days` | Days you read on |
| `stats.library`, `stats.favorites` | Titles in the library, and favorites |
| `stats.unread` | Unread chapters in the library |
| `stats.pace` | Chapters per week since you started |
| `library` | The titles of the library |
| `reads` | Every chapter read. `reads(30)` is the last 30 days, `reads('today')` is today |
| `today` | Today, as a day number |

## 4. Formulas

Formulas use numbers, text in single quotes, `true` and `false`, and names.

| | |
| --- | --- |
| Sums | `+ - * / %` and `^` for powers. `+` joins text when either side is text |
| Comparisons | `== != < <= > >=`. Text compares without minding capitals |
| Logic | `&&` (or `and`), `\|\|` (or `or`), `!` (or `not`), and `test ? a : b` |
| Numbers | `round(x)`, `round(x, 1)`, `min`, `max`, `abs`, `floor`, `ceil`, `sqrt`, `pow`, `log` (natural), `log10`, `exp`, `clamp(x, low, high)`, `percent(part, whole)`, `number(text)` to read a number from text |
| Choosing | `if(test, a, b)` |
| Text | `contains(text, 'word')`, `upper`, `lower`, `trim`, `len`, `text(x, 1)` for a number with one decimal |

`round` takes halves up, so `round(2.5)` is 3.

## 5. Lists

Lists are titles (`library`), reads (`reads`), or **series**: labelled numbers, such as how many titles each genre has. Charts draw series.

| Function | What it does |
| --- | --- |
| `filter(list, condition)` | Keeps the items the condition holds for |
| `count(list)`, `count(list, condition)` | How many items, or how many the condition holds for |
| `countBy(list, 'key')` | A series of how many there are of each key, the most first. Titles count by `genre`, `kind`, `status`, `source` or `author`. Reads also count by `day`, `weekday`, `time`, `hour`, `month` and `title` |
| `top(series, n)` | The `n` biggest of a series. On another list, its first `n` items |
| `take(list, n)` | The first `n` items |
| `sort(list, 'key')`, `sort(list, 'key', 'asc')` | Titles by `name`, `added`, `unread`, `rating`, `chapters` or `last` read. A series by `value` or `label` |
| `reverse(list)` | The list backwards |
| `sumOf(list, value)`, `avgOf`, `maxOf`, `minOf` | Works out a value for each item and adds them up, or takes their average, biggest or smallest |
| `sum`, `avg`, `min`, `max` | Over the values of a series, or over numbers given |
| `titlesOf(reads)` | The titles of some reads, the most recently read first |
| `first(list)`, `last(list)` | The label of the first or last point of a series, or the name of the first or last title |

Inside a condition or a value per item, the item's own names come first:

| Item | Names |
| --- | --- |
| Title | `name`, `author`, `kind` (`Manga`, `Novel`, `Anime`), `status` (`Ongoing`, `Completed`, `Hiatus`, `Cancelled`, `Unknown`), `genres`, `source`, `unread`, `favorite`, `rating`, `chapters`, `added` |
| Read | `day`, `daysAgo`, `hour`, `weekday` (Monday is 1), `at`, and the names of its title |
| Point of a series | `label`, `value` |

```text
filter(library, unread > 0 && kind == 'Manga')
count(reads(7), contains(genres, 'Romance'))
sumOf(filter(library, favorite), unread)
top(countBy(reads(90), 'title'), 5)
```

## 6. Views

A view is a JSON object with one of these keys. The value of that key is a formula.

| View | Example | Other keys |
| --- | --- | --- |
| Big number | `{ "number": "stats.streak" }` | `label`, `caption`, `color` |
| Ring | `{ "ring": "stats.month", "max": 60 }` | `max` (default 100), `label`, `color`, `show`: `"value"` to show the value in place of the percent |
| Bar | `{ "bar": "stats.week", "max": 20 }` | `max`, `label`, `color` |
| Chart | `{ "chart": "countBy(library, 'genre')" }` | `style` and the options in [Charts](#charts), `label` |
| List | `{ "list": "top(countBy(library, 'author'), 5)" }` | `label`. Takes a series or titles |
| Covers | `{ "covers": "take(titlesOf(reads(30)), 10)" }` | `label` |
| Heatmap | `{ "heatmap": "reads(365)" }` | `weeks` (4 to 53, default 26), `color`, `shape`: `square`, `round` (the default) or `circle`; `label` |
| Text | `{ "text": "Read {stats.month} this month" }` | `style`: `title`, `body` or `caption`. The text itself is plain, with formulas in braces |
| Stack | `{ "stack": [ view, view ] }` | Views one under the other |
| Row | `{ "row": [ view, view ] }` | Views side by side |
| Choice | `{ "if": "stats.streak > 0", "then": view, "else": view }` | `else` is optional |
| Section | `{ "section": "year" }` | A part of the profile as it came: `figures`, `year`, `continue` or `statistics` |

### Charts

| `style` | What it draws |
| --- | --- |
| `bars` (the default) | A bar across for each point, with its label and value |
| `columns` | A column up for each point, with labels under them |
| `line` | A line through the points, with a dot on each |
| `area` | A line with the space under it filled |
| `dots` | A thin line across for each point, with a dot at its value |
| `donut`, `pie` | A ring cut into slices, or a whole pie, with a key. Past six points, the rest go into one grey slice |
| `radial` | Rings inside each other, one for each of the first five points |
| `share` | One bar split into the share of each point, with percents in the key |

| Option | What it does |
| --- | --- |
| `color` | The colour of the chart |
| `colors` | A list of colours for the points in turn, such as `["teal", "amber", "#E5554F"]` |
| `values` | `false` hides the numbers, and `true` shows them over columns |
| `labels` | `false` hides the labels and the key |
| `height` | How tall the chart is, in dp, for columns, lines, areas, round charts and the share bar |
| `max` | The top of the scale, such as `100` for percents. Without it, the biggest value is the top |
| `smooth` | `true` curves a line or an area through its points |

A colour is one of the theme (`primary`, `secondary`, `tertiary`, `error`, `outline`), a name (`red`, `orange`, `amber`, `yellow`, `lime`, `green`, `teal`, `cyan`, `blue`, `indigo`, `purple`, `pink`, `brown`, `gray`), or `#RRGGBB`.

```json
{
  "title": "This month",
  "view": { "chart": "countBy(reads(30), 'day')", "style": "area", "color": "teal", "smooth": true, "height": 140 }
}
```

### Sizes

Each kind of view has a smallest size, and a block is never drawn or resized smaller than what it shows needs. A number or a bar needs 2 × 1, a ring or a list 2 × 2, a chart or a heatmap 3 × 2, covers 3 × 3, and a section the whole width at the height of its content. A stack adds up the sizes of its views.

## 7. Examples

Finished titles, and how many are left:

```json
{
  "let": {
    "done": "count(library, status == 'Completed' && unread == 0)",
    "all": "stats.library"
  },
  "view": { "row": [
    { "number": "done", "label": "Finished" },
    { "ring": "done", "max": "all", "label": "{all - done} to go" }
  ]}
}
```

What you read most this season:

```json
{
  "title": "Last 90 days",
  "view": { "stack": [
    { "chart": "top(countBy(reads(90), 'genre'), 5)", "style": "donut" },
    { "list": "top(countBy(reads(90), 'title'), 3)", "label": "Most read" }
  ]}
}
```

A streak that cheers you on:

```json
{
  "view": { "if": "stats.streak >= 7",
    "then": { "text": "{stats.streak} days in a row!", "style": "title" },
    "else": { "number": "stats.streak", "label": "Current streak", "caption": "{7 - stats.streak} more for a week" }
  }
}
```

## 8. When something is wrong

Once the text is valid JSON, the block shows what went wrong in place of its view, with where: `let "done": ...` for a value, or a path such as `view.stack[1].chart: ...` for a view. A name or function the script does not know is said with the place in the formula where it is, counted from 1. If the text is not valid JSON, the line under the script says where, as a line and a column, and what is wrong. The **tidy** button in the toolbar over the script lays the JSON out one key to a line once it can be read.
