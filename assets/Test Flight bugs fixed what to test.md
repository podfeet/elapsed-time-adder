# Test Flight bugs fixed/what to test

## Ways to give feedback in order of preference:

- open an issue at https://github.com/podfeet/elapsed-time-adder
- send me an email at allison@podfeet.com
- least desirable - feedback inside TestFlight. There's no way for me to write back to you or keep track of the ideas.



## Changes & things to test

- Lowered minimum requirements to iOS 18.6, macOS 15.6, visionOS 2.6
- Added hide keyboard button to make it easier to get to the add row, export, and reset buttons without scrolling in a reduced window area



- - 

- New Feature

  - Changed "a Podfeet App" to be an about button that opens a card giving feedback and other options

- Fixed/improved in this build (mostly thanks to Mike Price):

  - CSV AirDrop should now correctly create only one file.
  - HH:MM:SS and CSV exports to file with titles `Elapsed Time Adder.txt`  and `Elapsed Time Adder.csv`  respectively. 
  - Title row is now correctly provided for both CSV and HH:MM:SS exports
  - Rows with data but no title entered will be called "Row 1", "Row 2", etc. (instead of just "Row"
  - Blank rows are no longer exported, and their row numbers are skipped, so you don't get Row 1, Row 3
  - Negative values are disallowed in single cells, and a single minus sign without values now also throws an error.
  - Explanation of why a spreadsheet is clearer - swapped in "time-of-day" for "absolute" time
  - Changed "a Podfeet App" to be an about button that opens a card giving feedback and other options - test this!

  Mike suggested that the app should have a more obvious look to the Add Another Row button. I hate to have **too** many colors, but that would differentiate it from the two Export buttons. Any ideas would be appreciated.

  

## New screenshots

At least one:

- **Video** (+9:10)
- **Intro music** (−0:12)
- **Audio offset** (+1:16)

Title: Never do timestamp math in your head again

12M 43S + 7.5M 22S →  20 min 35 sec

12min 43sec  + 7.5min 22sec =20 mins 35 secs 

^^^ this was calculated automatically in Typora!