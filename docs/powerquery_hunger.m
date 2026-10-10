let
    Source = Csv.Document(File.Contents("C:\Users\USER\Downloads\hfid_hv1.csv"),[Delimiter=",", Columns=21, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Change Type" = Table.TransformColumnTypes(Source,{{"Column1", type text}, {"Column2", type text}, {"Column3", type text}, {"Column4", type text}, {"Column5", type text}, {"Column6", type text}, {"Column7", type text}, {"Column8", type text}, {"Column9", type text}, {"Column10", type text}, {"Column11", type text}, {"Column12", type text}, {"Column13", type text}, {"Column14", type text}, {"Column15", type text}, {"Column16", type text}, {"Column17", type text}, {"Column18", type text}, {"Column19", type text}, {"Column20", type text}, {"Column21", type text}}),
    #"Removed Columns" = Table.RemoveColumns(#"Change Type",{"Column2", "Column19", "Column20", "Column6", "Column8", "Column9", "Column10", "Column11", "Column12", "Column14", "Column15", "Column17", "Column18"}),
    #"Filtered Rows" = Table.SelectRows(#"Removed Columns", each ([Column21] = "iso3" or [Column21] = "NGA")),
    #"Removed Columns1" = Table.RemoveColumns(#"Filtered Rows",{"Column21"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns1",{{"Column1", "year_month"}, {"Column3", "State"}, {"Column4", "LGA"}, {"Column5", "FEWS_Phase"}, {"Column7", "CH_Phase"}, {"Column13", "FCS_Insufficient"}, {"Column16", "rCSI_Crisis"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "Date", each #date(Number.FromText(Text.Start([year_month],4)), Number.FromText(Text.End([year_month],2)), 1)),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Custom",{{"Date", type date}}),
    #"Filtered Rows1" = Table.SelectRows(#"Changed Type", each ([year_month] <> "year_month")),
    #"Inserted Year" = Table.AddColumn(#"Filtered Rows1", "Year", each Date.Year([Date]), Int64.Type),
    #"Inserted Month" = Table.AddColumn(#"Inserted Year", "Month", each Date.Month([Date]), Int64.Type),
    #"Renamed Columns1" = Table.RenameColumns(#"Inserted Month",{{"Month", "Month_Num"}}),
    #"Inserted Month Name" = Table.AddColumn(#"Renamed Columns1", "Month Name", each Date.MonthName([Date]), type text),
    #"Renamed Columns2" = Table.RenameColumns(#"Inserted Month Name",{{"Month Name", "Month_Name"}}),
    #"Removed Columns2" = Table.RemoveColumns(#"Renamed Columns2",{"year_month"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Removed Columns2",{{"Year", Int64.Type}, {"Month_Num", Int64.Type}, {"FEWS_Phase", Int64.Type}, {"CH_Phase", Int64.Type}}),
    #"Filtered Rows2" = Table.SelectRows(#"Changed Type1", each true),
    #"Changed Type2" = Table.TransformColumnTypes(#"Filtered Rows2",{{"FCS_Insufficient", type number}, {"rCSI_Crisis", type number}, {"LGA", type text}, {"Month_Name", type text}, {"State", type text}}),
    #"Added Custom1" = Table.AddColumn(#"Changed Type2", "Country", each "Nigeria"),
    #"Added Custom2" = Table.AddColumn(#"Added Custom1", "LGA_Key", each [State] & " - " & [LGA]),
    #"Added Custom3" = Table.AddColumn(#"Added Custom2", "Zone", each if List.Contains({"Benue","Kogi","Kwara","Nasarawa","Niger","Plateau","Federal Capital Territory"}, [State]) then "North Central"
else if List.Contains({"Adamawa","Bauchi","Borno","Gombe","Taraba","Yobe"}, [State]) then "North East"
else if List.Contains({"Jigawa","Kaduna","Kano","Katsina","Kebbi","Sokoto","Zamfara"}, [State]) then "North West"
else if List.Contains({"Abia","Anambra","Ebonyi","Enugu","Imo"}, [State]) then "South East"
else if List.Contains({"Akwa Ibom","Bayelsa","Cross River","Delta","Edo","Rivers"}, [State]) then "South South"
else if List.Contains({"Ekiti","Lagos","Ogun","Ondo","Osun","Oyo"}, [State]) then "South West"
else "Unassigned"),
    #"Added Custom4" = Table.AddColumn(#"Added Custom3", "FEWS_P3Plus", each if [FEWS_Phase] = null then null else if [FEWS_Phase] >= 3 then 1 else 0),
    #"Added Custom5" = Table.AddColumn(#"Added Custom4", "CH_P3Plus", each if [CH_Phase] = null then null else if [CH_Phase] >= 3 then 1 else 0),
    #"Added Custom6" = Table.AddColumn(#"Added Custom5", "Phase_Agree", each if [FEWS_Phase] = null or [CH_Phase] = null then null else if [FEWS_Phase] = [CH_Phase] then 1 else 0),
    #"Changed Type3" = Table.TransformColumnTypes(#"Added Custom6",{{"Country", type text}, {"LGA_Key", type text}, {"Zone", type text}, {"FEWS_P3Plus", Int64.Type}, {"CH_P3Plus", Int64.Type}, {"Phase_Agree", Int64.Type}}),
    #"Added Custom7" = Table.AddColumn(#"Changed Type3", "Hidden_Hunger_Flag", each if [CH_Phase] = null or [FCS_Insufficient] = null then null else if [CH_Phase] <= 2 and [FCS_Insufficient] >= 0.5 then 1 else 0),
    #"Changed Type4" = Table.TransformColumnTypes(#"Added Custom7",{{"Hidden_Hunger_Flag", Int64.Type}}),
    #"Removed Duplicates" = Table.Distinct(#"Changed Type4", {"State", "LGA", "Date"})
in
    #"Removed Duplicates"