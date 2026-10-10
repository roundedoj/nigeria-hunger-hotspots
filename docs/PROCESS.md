# Process Documentation and Standard Operating Procedure
## Hunger Hotspots and Blind Spots in Nigeria (2011 to 2024)

Author: Justice Chikesirim Obisike
Document type: Process documentation and replication SOP
Output documented: six-page Power BI report and PDF, "Hunger Hotspots and Blind Spots in Nigeria"

---

## 1. Purpose and scope

**Purpose.** This document records how the report was produced, so that a skilled reader can understand every decision, reproduce the output, audit the numbers, or improve the work.

**In scope:** data sourcing and licensing, profiling, extraction of Nigerian records, cleaning and wrangling in Excel Power Query, the Power BI data model, all DAX calculations, the design system (canvas, grid, colour, typography, components), quality assurance and export.

**Out of scope:** predictive modelling or machine learning (planned as a separate project), causal analysis, and population-weighted estimates (population is not in the source data).

**Intended readers:** analysts, students, reviewers and practitioners in food security, agricultural data science and business intelligence.

---

## 2. Summary of the workflow

Source (HFID on HDX) > Profile > Extract Nigeria (Power Query) > Clean > Wrangle (helper columns) > Validate counts > Load to Power BI > Model (Date table, relationship) > Measures (DAX) > Design system > Build 13 visuals across 6 pages > QA against independent recalculation > Export PDF.

---

## 3. Inputs, tools and environment

**Data**
- Harmonized Food Insecurity Dataset (HFID), static version hv1, file `hfid_hv1.csv` (311,838 rows, 21 columns, 80 countries, June 2007 to May 2024).
- Publisher: Joint Research Centre (JRC), European Commission.
- Distribution: Humanitarian Data Exchange (HDX), https://data.humdata.org/dataset/harmonized-food-insecurity-dataset-hfid
- Reference paper: "A monthly sub-national Harmonized Food Insecurity Dataset for comprehensive analysis and predictive modeling", *Scientific Data* (2025), DOI 10.1038/s41597-025-05034-4.
- Licence: Creative Commons Attribution 4.0 (CC BY 4.0). Attribution is given on every report page.

**Software**
- Microsoft Excel with Power Query (Get and Transform).
- Microsoft Power BI Desktop 2.157.1354.0, 64-bit (August 2026).
- Font: Outfit (Google Fonts), installed on Windows (installing for all users is recommended).
- Reference figures independently recalculated in Python (pandas) from the cleaned workbook.

**Indicators in HFID used for Nigeria**
- FEWS NET phase (Famine Early Warning Systems Network), IPC-compatible, 1 to 5.
- CH phase (Cadre Harmonisé, the West African IPC-compatible framework), 1 to 5.
- WFP real-time Food Consumption Score (FCS): share of people with insufficient (poor or borderline) consumption.
- WFP real-time reduced Coping Strategies Index (rCSI): share of people at or above the crisis-level threshold defined in the HFID paper.

---

## 4. Procedure

### Step 1. Data sourcing and selection
- Requirement: real, credible, downloadable (CSV/XLSX), Nigeria-specific records, at least 10 columns and 2,000 rows, recent data, suitable for later machine learning.
- Selected HFID because it is peer-reviewed, openly licensed, and combines three Nigerian monitoring systems at LGA level in one monthly table.

### Step 2. Profiling (before any design decision)
Nigeria subset (`iso3 = NGA`):
- 49,163 rows; 82 months (January 2011 to May 2024); 37 states including FCT; 775 state-LGA pairs; no duplicates on month, state and LGA.
- FEWS NET: 31,734 non-blank values, 41 months, 774 LGAs.
- CH: 11,697 non-blank values, October 2020 to May 2024, October to December and March to May windows, 33 states, 564 LGAs.
- WFP survey indicators: 17,251 non-blank values each, monthly July 2021 to February 2024, 28 states, 584 LGAs.
- Survey values are identical across LGAs within a state-month (state-level estimates).
- Uninformative for Nigeria: `ha_ipcch`, `set_ipcch`, `rfg_ipcch` (0 or blank), `ha_fews` (0 except 21 rows), `fcs_lit` and `rcsi_lit` (sparse, 2016 to 2018 only).
- No Nigerian record reaches Phase 5.

### Step 3. Extraction and handling (Excel Power Query)
1. Data > Get Data > From File > From Text/CSV. File origin 65001 (UTF-8), comma delimiter, data type detection off, Transform Data.
2. Filter `iso3` = `NGA` (code-based filter avoids confusion between Niger State and the country Niger).
3. Expected result: 49,163 rows.

### Step 4. Cleaning
1. Remove 14 columns: `ADMIN0`, `iso2`, `region`, `iso3` (constant); `ha_fews`, `ha_ipcch`, `set_ipcch`, `rfg_ipcch` (empty); `fcs_lit`, `rcsi_lit` (sparse); `fcs_rt max`, `fcs_rt min`, `rcsi_rt max`, `rcsi_rt min` (not needed).
2. Rename: `ADMIN1` > `State`; `ADMIN2` > `LGA`; `ipc_phase_fews` > `FEWS_Phase`; `ipc_phase_ipcch` > `CH_Phase`; `fcs_rt mean` > `FCS_Insufficient`; `rcsi_rt mean` > `rCSI_Crisis`.
3. Set types: whole number (phases, year, month number), decimal (survey shares), text (names), date (Date).
4. Missing values: retained as blank in all source columns. Blank means "not assessed"; no imputation or zero-filling.
5. Duplicate test on Date, State, LGA: row count unchanged (49,163).

### Step 5. Wrangling (derived columns)
```
Date = #date(Number.FromText(Text.Start([year_month],4)), Number.FromText(Text.End([year_month],2)), 1)
Year, Month_Num, Month_Name  (Add Column > Date)
Country = "Nigeria"
LGA_Key = [State] & " - " & [LGA]
Zone = state-to-zone mapping (six geopolitical zones, "Unassigned" as a catch-all for errors)
FEWS_P3Plus = if [FEWS_Phase] = null then null else if [FEWS_Phase] >= 3 then 1 else 0
CH_P3Plus = if [CH_Phase] = null then null else if [CH_Phase] >= 3 then 1 else 0
Phase_Agree = if [FEWS_Phase] = null or [CH_Phase] = null then null else if [FEWS_Phase] = [CH_Phase] then 1 else 0
Hidden_Hunger_Flag = if [CH_Phase] = null or [FCS_Insufficient] = null then null else if [CH_Phase] <= 2 and [FCS_Insufficient] >= 0.5 then 1 else 0
```
Rationale: `LGA_Key` resolves six LGA names shared by two states; 0/1 columns turn shares into simple averages; `Country` supports correct map placement.

### Step 6. Validation before loading
- Non-blank counts: FEWS_Phase 31,734; CH_Phase 11,697; FCS_Insufficient and rCSI_Crisis 17,251 each.
- Zone: no "Unassigned" values.
- Output: query `Hunger`, loaded to `HFID_Nigeria_Clean.xlsx` (49,163 rows, 17 columns).

### Step 7. Power BI data model
1. Load only the `Hunger` table.
2. Disable Auto date/time (Options > Current File > Data Load).
3. Data categories: `State` (State or Province), `Country` (Country/Region). Sort `Month_Name` by `Month_Num`. Set "Don't summarize" on year, month and phase columns.
4. Date table:
```
Dates =
VAR MinY = YEAR ( MIN ( Hunger[Date] ) )
VAR MaxY = YEAR ( MAX ( Hunger[Date] ) )
RETURN
ADDCOLUMNS (
    CALENDAR ( DATE ( MinY, 1, 1 ), DATE ( MaxY, 12, 31 ) ),
    "Year", YEAR ( [Date] ), "Month Num", MONTH ( [Date] ), "Month", FORMAT ( [Date], "mmm" )
)
```
5. Mark `Dates` as date table; relationship `Dates[Date]` (one) to `Hunger[Date]` (many), single direction; hide date columns in `Hunger`.
6. Create an empty `_Measures` table to hold all measures.

### Step 8. Calculations (DAX)
Calculated columns:
```
CH Phase Label = SWITCH ( Hunger[CH_Phase], 1, "1 Minimal", 2, "2 Stressed", 3, "3 Crisis", 4, "4 Emergency", BLANK () )
FEWS Phase Label = SWITCH ( Hunger[FEWS_Phase], 1, "1 Minimal", 2, "2 Stressed", 3, "3 Crisis", 4, "4 Emergency", BLANK () )
```
(Sorted by the numeric phase columns.)

Measures:
```
Avg FCS = AVERAGE ( Hunger[FCS_Insufficient] )
Avg rCSI = AVERAGE ( Hunger[rCSI_Crisis] )
FEWS P3+ Share = AVERAGE ( Hunger[FEWS_P3Plus] )
CH P3+ Share = AVERAGE ( Hunger[CH_P3Plus] )
FEWS Emergency LGAs = CALCULATE ( DISTINCTCOUNT ( Hunger[LGA_Key] ), Hunger[FEWS_Phase] = 4 )
CH Emergency LGAs = CALCULATE ( DISTINCTCOUNT ( Hunger[LGA_Key] ), Hunger[CH_Phase] = 4 )
CH Assessed LGAs = CALCULATE ( DISTINCTCOUNT ( Hunger[LGA_Key] ), NOT ISBLANK ( Hunger[CH_Phase] ) )
Chronic LGAs = COUNTROWS ( FILTER ( VALUES ( Hunger[LGA_Key] ), [CH P3+ Share] >= 0.5 ) )
Recurrent LGAs = COUNTROWS ( FILTER ( VALUES ( Hunger[LGA_Key] ), [CH P3+ Share] > 0 && [CH P3+ Share] < 0.5 ) )
Hotspot LGAs Total = COALESCE ( [Chronic LGAs], 0 ) + COALESCE ( [Recurrent LGAs], 0 )
Avg FCS State-Weighted = AVERAGEX ( VALUES ( Hunger[State] ), CALCULATE ( AVERAGE ( Hunger[FCS_Insufficient] ) ) )
Avg rCSI State-Weighted = AVERAGEX ( VALUES ( Hunger[State] ), CALCULATE ( AVERAGE ( Hunger[rCSI_Crisis] ) ) )
States Reporting = CALCULATE ( DISTINCTCOUNT ( Hunger[State] ), NOT ISBLANK ( Hunger[FCS_Insufficient] ) )
FCS Late 2022 = CALCULATE ( [Avg FCS], DATESBETWEEN ( Dates[Date], DATE ( 2022, 10, 1 ), DATE ( 2022, 12, 31 ) ) )
FCS Late 2023 = CALCULATE ( [Avg FCS], DATESBETWEEN ( Dates[Date], DATE ( 2023, 10, 1 ), DATE ( 2023, 12, 31 ) ) )
FCS Change (pp) = ( [FCS Late 2023] - [FCS Late 2022] ) * 100        -- format +0.0;-0.0;0.0
Overlap LGA-Months = CALCULATE ( COUNTROWS ( Hunger ), FILTER ( Hunger, NOT ISBLANK ( Hunger[FEWS_Phase] ) && NOT ISBLANK ( Hunger[CH_Phase] ) ) )
Phase Agreement % = AVERAGE ( Hunger[Phase_Agree] )
FEWS Coverage % = COALESCE ( DIVIDE ( CALCULATE ( DISTINCTCOUNT ( Hunger[LGA_Key] ), NOT ISBLANK ( Hunger[FEWS_Phase] ) ), DISTINCTCOUNT ( Hunger[LGA_Key] ) ), 0 )
CH Coverage % = COALESCE ( DIVIDE ( CALCULATE ( DISTINCTCOUNT ( Hunger[LGA_Key] ), NOT ISBLANK ( Hunger[CH_Phase] ) ), DISTINCTCOUNT ( Hunger[LGA_Key] ) ), 0 )
Survey Coverage % = COALESCE ( DIVIDE ( CALCULATE ( DISTINCTCOUNT ( Hunger[LGA_Key] ), NOT ISBLANK ( Hunger[FCS_Insufficient] ) ), DISTINCTCOUNT ( Hunger[LGA_Key] ) ), 0 )
Sources Available = INT ( NOT ISEMPTY ( FILTER ( Hunger, NOT ISBLANK ( Hunger[FEWS_Phase] ) ) ) )
                  + INT ( NOT ISEMPTY ( FILTER ( Hunger, NOT ISBLANK ( Hunger[CH_Phase] ) ) ) )
                  + INT ( NOT ISEMPTY ( FILTER ( Hunger, NOT ISBLANK ( Hunger[FCS_Insufficient] ) ) ) )
Hidden Hunger LGA-Months = SUM ( Hunger[Hidden_Hunger_Flag] )
Eligible LGA-Months = CALCULATE ( COUNTROWS ( Hunger ), FILTER ( Hunger, NOT ISBLANK ( Hunger[Hidden_Hunger_Flag] ) && Hunger[CH_Phase] <= 2 ) )
Hidden Hunger Rate = DIVIDE ( [Hidden Hunger LGA-Months], [Eligible LGA-Months] )
Yobe Latest = CALCULATE ( [CH P3+ Share], Hunger[State] = "Yobe", Dates[Year] = 2024 )
Poor Diets Feb 2024 = CALCULATE ( [Avg FCS State-Weighted], Dates[Date] = DATE ( 2024, 2, 1 ) )
Survey Blind Spot States = DISTINCTCOUNT ( Hunger[State] ) - [States Reporting]
```
Design notes:
- Shares use the average of 0/1 columns, so the denominator is always "assessed areas only".
- State-weighted averages correct for survey values being repeated across LGAs.
- Explicit `NOT ISBLANK` tests prevent DAX from treating blanks as zero in comparisons.
- The mismatch rate (`Hidden Hunger Rate`) uses only Phase 1 and 2 area-months as its base. The internal name is shorthand; in nutrition, "hidden hunger" usually refers to micronutrient deficiency, so public wording describes it as a ratings-survey mismatch.

### Step 9. Design system
- **Canvas:** 720 x 900 px (4:5 portrait), chosen for LinkedIn and Instagram carousel compatibility; one page per slide.
- **Grid:** every visual 672 x 240 px; slots at (24, 84), (24, 336), (24, 588); 24 px side margins; 12 px gaps.
- **Header:** green accent rectangle 12 x 48 at (24, 18); title text box 652 x 32 at (44, 12); subheader text box 460 x 24 at (44, 46).
- **Footer:** text box 596 x 30 at (24, 866) with source and page-specific definitions; page number 60 x 18 at (636, 870).
- **Palette (Moss Slate):** BG `#F7F8F3`, INK `#17252A`, GREEN `#3F7D4E`; tints INK72 `#566062`, INK35 `#A9AEAD`, INK12 `#DCDFDB`, GREEN50 `#9BBAA0`, GREEN15 `#DBE6DA`. Contrast: INK on BG about 14.7:1; GREEN on BG about 4.6:1.
- **Typography:** Outfit (Regular, SemiBold, Bold); minimum 8 pt; visual titles 11 pt; subtitles and labels 8 to 9 pt; page title 15 pt.
- **Theme file:** JSON setting `dataColors`, `background`, `foreground`, `tableAccent` and `textClasses` (fonts and sizes), loaded via View > Themes > Browse for themes.
- **Visual card style:** insight title (states a finding the chart shows), subtitle (what is measured), green divider, BG background, INK12 rounded border, soft shadow.
- **Data labels and axes:** value axes hidden on labelled bar and column charts after fixing the axis minimum at 0; axes kept on line and scatter charts.
- **Writing rules:** plain language, no claims beyond what each chart shows, no em dashes, definitions in footers.

### Step 10. Report structure (6 pages, 13 visuals)
1. Severity and persistence: Q1 line (Crisis-or-worse share over time, FEWS NET and CH); Q2 clustered columns (Emergency LGAs per year); Q3 stacked columns (chronic and recurrent hotspots by state).
2. Where: Q4 filled map and top-7 bar (March to May 2024; eight states had a share above zero, the eighth being Bauchi at 5.0%); Q5 zone-by-year heat map.
3. Households: Q6 state-weighted monthly trends; Q7 top-10 rise in poor diets (percentage points); Q8 state scatter with trend line.
4. Agreement: Q9 household results by CH phase; Q10 FEWS NET by CH agreement matrix; Q12 ratings-survey mismatch by state.
5. Gaps: Q11 states with fewer than three sources; Q11 national coverage by year; interpretation note.
6. Summary: three text panels (findings, trust and gaps, recommendations).

### Step 11. Quality assurance
Each visual was checked against independent recalculation in Python. Reference values:
- Q1: FEWS NET peak 12.0% (June 2022); CH 16.9% (March to May 2024).
- Q2: FEWS NET 24 LGAs (2017); CH 6, 4, 2 (2020 to 2022).
- Q3: chronic Borno 20, Katsina 11, Yobe 7, Zamfara 4, Adamawa 1 (total 43); recurrent 98; 564 LGAs assessed.
- Q4: Yobe 82.4%, Borno 81.5%, Zamfara 71.4%, Katsina 67.6%, Sokoto 65.2%, Kaduna 30.4%, Adamawa 14.3%.
- Q5: North East 35.7% and North West 29.6% in 2024.
- Q6: poor diets 26.9% (October 2022) to 56.6% (February 2024).
- Q7: Katsina +34.3, Taraba +28.9, Kaduna +28.4.
- Q9: poor diets 36.9%, 42.8%, 46.5% by CH Phase 1 to 3.
- Q10: 1,952 shared assessments; 1,098 agreements (56.3%).
- Q11: four states with one source, five with two; CH coverage 72.6% and survey 75.4% in 2024.
- Q12: Sokoto 50.5%; national rate 22.0% (1,495 of 6,795).
Additional checks: no leftover filters on copied visuals; titles and subtitles claim only what is visible; all text at least 8 pt; no em dashes; PDF reviewed at phone size.

### Step 12. Export
File > Export > Export to PDF. The PDF embeds the Outfit font, so the design is preserved on devices without Outfit. The `.pbix` file does not embed fonts.

---

## 5. Outputs
- `HFID_Nigeria_Clean.xlsx`: cleaned Nigeria table with the Power Query steps saved inside.
- `HFID_Nigeria_Analysis.pbix`: Power BI report and model.
- `HFID_Nigeria_Analysis.pdf`: six-page shareable report.
- `HungerTheme.json`: theme file (colours and fonts).

---

## 6. Known limitations
- Shares count LGAs, not people; no population weighting.
- Survey indicators are state-level estimates repeated on each LGA.
- Sources differ in coverage and timing; blank means not assessed.
- CH 2020 and 2024 are partial years.
- Thresholds (chronic at 50% or more; mismatch at 50% or more poor diets) are judgement calls.
- Static data ending May 2024; descriptive analysis only, no causal claims.

---

## 7. Suggested improvements
1. Population-weighted shares using an external population source (with its own citation).
2. Sensitivity tests for the chronic and mismatch thresholds (40% and 60%).
3. Refresh with the dynamic HFID release when it becomes available.
4. Replace the Bing-based filled map with Azure Maps or a shape map if Bing map visuals become unavailable.
5. A follow-up machine-learning project to predict phase classifications using these features.

---

## 8. Change log (key decisions during the build)
- Dropped analysis of aid and displacement flags after profiling showed they are empty for Nigeria.
- Replaced a planned seasonality question with a month-by-month trajectory (too few survey months to separate season from trend).
- Corrected the mismatch-rate denominator to Phase 1 and 2 area-months only (22.0%, not 20.3%).
- Moved from mixed visual sizes to one fixed 672 x 240 slot and added a page for Theme D.
- Rewrote titles so each claims only what its chart shows.

---

## 9. Credit and licence
- Data: Harmonized Food Insecurity Dataset (HFID), Joint Research Centre of the European Commission, via the Humanitarian Data Exchange, CC BY 4.0. 
- This analysis and documentation: Justice Chikesirim Obisike (Developed with assistance from Claude)