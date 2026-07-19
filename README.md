# Team6_SmartEcoGymApp

# 1. The Hook /The problem!
Wearable devices collect large amounts of fitness data, but those raw numbers don't help most gym members understand their own workout performance. Whether someone is new to the gym or an experienced athlete, they're often left staring at a heart-rate graph with no idea what it actually means for their training. Smart Eco Gym takes that raw sensor data and turns it into something useful: estimated calories burned, a summary of each workout, a comparison of calories burned across different activities, and a clear recommendation of the user's highest calorie-burning workout.

# 2. The Audience
Gym members who use wearable devices ( gym people and experienced athletes) — who want clear, simple insight into their workout performance without needing to interpret raw sensor data themselves.

# 3. The Engine
Data files used:
- wearable_person_metadata.csv— per-person info: weight, fitness goal, fitness level, resting/max heart rate, BMR
- wearable_session_summary.csv —one row per session: duration, mean/max heart rate, cadence (used to populate the Workout Summary tab)
- wearable_sensor_data.mat —raw sensor data per session: heart rate over time, activity type, start/end times, plus a built-in MET reference table

Metrics computed
- Calories burned per session:Calories = MET × weight_kg × duration_hours, where MET (metabolic equivalent) comes from the activity's entry in the reference table
- Effort level: the person's mean heart rate during the session, expressed as a percentage of their estimated max heart rate

Data processing steps:
- Heart rate smoothing — a moving average (movmean, 25-sample window) is applied to the raw heart rate signal before computing the mean, to reduce sensor noise
- MET lookup — each session's activity type is matched against the reference table to pull the correct MET value 

# 4. The Features
Interactive components:
- Three import buttons — one each for the person CSV, session summary CSV, and sensor .mat file 
- A dropdown menu listing every workout session; selecting one instantly recalculates and updates every part of the app

Graph:
- A bar chart (Calories Graph tab) showing calories burned across every session that person has logged, so they can compare activities side by side

Visual indicator
- A color-coded lamp that turns green (strong effort, ≥70% of max HR), yellow (moderate effort, 50–70%), or red (light effort, <50%) based on the smoothed mean heart rate relative to that person's estimated max heart rate

Other displays
- Workout Recommendation tab — shows the selected person, their fitness goal, this session's calorie estimate, lamp which displays effort, and their single highest calorie-burning activity to date
- Workout Summary tab — lists that person's sessions (session ID, activity, duration, mean HR, max HR) pulled directly from the session summary CSV

# 5. The Manual
(Step-by-step instructions for a non-expert to download, open, and run the app)
1. Download all four files into the same folder: app1.mlapp, wearable_person_metadata.csv, wearable_session_summary.csv, and wearable_sensor_data.mat.
2. Open MATLAB, and set your Current Folder (top of the MATLAB window) to that folder.
3. Double-click app1.mlapp in the MATLAB file browser — this opens it in App Designer.
4. Click the green Run button (or press F5).
5. In the app window, click each of the three import buttons in turn:
   - Person Data → select wearable_person_metadata.csv
   - Session Data → select wearable_session_summary.csv
   - Mat Data → select wearable_sensor_data.mat
6. Once all three are loaded, use the dropdown menu (top right of the Calories Graph tab) to pick a workout session.
7. The calories graph updates automatically. Click the Workout Recommendation and Workout Summary tabs to see the rest of the results for that person.
8. To look at a different person or session, just pick a new item from the dropdown — no need to re-import anything.

# 6. The Reality Check
Known limitations / assumptions!
- All three files must be successfully imported before any results will display; if only some are loaded, the app will not work and the user will need to finish importing rather than showing partial results.
- The effort indicator uses a simplified 3-level scale (green/yellow/red) based on % of estimated max heart rate.
- If the sensor .mat file doesn't include its own MET reference table, the app falls back to a hardcoded table with the same standard MET values, so results stay consistent
