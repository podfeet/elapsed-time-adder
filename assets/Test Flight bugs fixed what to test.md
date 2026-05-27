# Test Flight bugs fixed/what to test

- CSV AirDrop should now correctly create only one file.
- HH:MM:SS and CSV exports to file now have titles `Elapsed Time Adder.txt`  and `Elapsed Time Adder.csv`  respectively. 
- Title row is now correctly provided for both CSV and HH:MM:SS exports
- Rows with data but no title entered will be called Row 1, Row 2, etc
- Blank rows are no longer exported and their row numbers skipped so you don't get Row 1, Row 3
- Negative values are disallowed in single cells, and a single minus sign without values now also throws an error.

