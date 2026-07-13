# Index Sorting And Scrollbars

## Sort Behavior

- The Index page defaults to number sorting.
- Opening the sort dialog does not change sort state.
- Dismissing the sort dialog does not change sort state.
- Sort changes only when the user taps `በቁጥር` or `በስም`.
- Search stores the previous sort mode and restores it when cleared.

## Alphabet Rail

- The alphabet rail is fixed, not scrollable.
- It only shows groups that have songs.
- Tap or drag over a letter group jumps to that section.
- The rail stays above the bottom navigation padding.

## Number Rail

- The number rail appears only for large number-sorted lists.
- Jump points: `1`, `50`, `100`, `150`, `200`, `250`, `300`.
- Tapping a point scrolls to the nearest hymn number at or above that point.

## QA Steps

1. Open `ማውጫ`.
2. Tap sort and dismiss it; order should not change.
3. Choose `በስም`, then choose `በቁጥር`; both switches should work repeatedly.
4. In name mode, alphabet rail should not scroll independently.
5. In number mode, number rail should jump near the selected range.
