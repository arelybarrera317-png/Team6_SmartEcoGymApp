classdef app1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        TabGroup             matlab.ui.container.TabGroup
        graphTab             matlab.ui.container.Tab
        ImportMatButton      matlab.ui.control.Button
        ImportSummaryButton  matlab.ui.control.Button
        ImportPersonButton   matlab.ui.control.Button
        DropDown             matlab.ui.control.DropDown
        DropDownLabel        matlab.ui.control.Label
        caloriesAxes         matlab.ui.control.UIAxes
        workoutRecTab        matlab.ui.container.Tab
        RecText              matlab.ui.control.TextArea
        RecTextLabel         matlab.ui.control.Label
        EffortLamp           matlab.ui.control.Lamp
        EffortLampLabel      matlab.ui.control.Label
        WorkoutSumTab        matlab.ui.container.Tab
        SumText              matlab.ui.control.TextArea
        TextArea2Label       matlab.ui.control.Label
    end

    
    properties (Access = private)
        Data struct = struct('People', table(), 'SessionSummary', table(), 'Sessions', struct([]), 'METRef', table())
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.RecText.Value = {'Click the import buttons to get started.'};
        end

        % Callback function: not associated with a component
        function ImportPersonButtonValueChanged(app, event)
                %ignore this lowkey on the low
        end

        % Value changed function: DropDown
        function DropDownValueChanged(app, event)
                if isempty(app.Data.People) || isempty(app.Data.Sessions)
                app.RecText.Value = {'Import your data first.'};
                return
            end
            if isempty(app.DropDown.ItemsData)
                return
            end

            sessIdx = app.DropDown.ItemsData(app.DropDown.ValueIndex);
            sess = app.Data.Sessions(sessIdx);
            personRow = app.Data.People(strcmp(app.Data.People.person_id, sess.person_id), :);

            durationHours = (sess.end_time_sec - sess.start_time_sec) / 3600;

            row = strcmpi(app.Data.METRef.activity_type, sess.activity_type);
            if any(row)
                met = app.Data.METRef.typical_MET(find(row,1));
            else
                met = 5;
            end
            calories = met * personRow.weight_kg * durationHours;

            hrSmoothed = movmean(sess.heart_rate, 25);
            meanHR = mean(hrSmoothed);

            personSessIdx = find(strcmp({app.Data.Sessions.person_id}, sess.person_id));
            actLabels = strings(numel(personSessIdx),1);
            calValues = zeros(numel(personSessIdx),1);
            for k = 1:numel(personSessIdx)
                s2 = app.Data.Sessions(personSessIdx(k));
                d2 = (s2.end_time_sec - s2.start_time_sec) / 3600;

                row2 = strcmpi(app.Data.METRef.activity_type, s2.activity_type);
                if any(row2)
                    m2 = app.Data.METRef.typical_MET(find(row2,1));
                else
                    m2 = 5;
                end

                calValues(k) = m2 * personRow.weight_kg * d2;
                actLabels(k) = strrep(s2.activity_type, '_', ' ');
            end
            cla(app.caloriesAxes);
            xvals = 1:numel(calValues);
            bar(app.caloriesAxes, xvals, calValues, 'FaceColor', [0.30 0.55 0.85]);
            app.caloriesAxes.XTick = xvals;
            app.caloriesAxes.XTickLabel = actLabels;
            title(app.caloriesAxes, sprintf('Calories Burned (Cal) Vs. Type of Exercise - %s', personRow.person_id));

            [bestCal, bestIdx] = max(calValues);
            app.RecText.Value = { ...
                sprintf('Person: %s   Goal: %s', personRow.person_id, personRow.fitness_goal), ...
                sprintf('This session: %s, %.0f kcal (%.0f min)', strrep(sess.activity_type,'_',' '), calories, durationHours*60), ...
                '', ...
                sprintf('Best activity so far: %s (%.0f kcal)', actLabels(bestIdx), bestCal)};

            pctMaxHR = 100 * meanHR / personRow.estimated_max_hr_bpm;
            if pctMaxHR >= 70
                app.EffortLamp.Color = [0.20 0.70 0.30];
            elseif pctMaxHR >= 50
                app.EffortLamp.Color = [0.95 0.75 0.10];
            else
                app.EffortLamp.Color = [0.85 0.20 0.20];
            end

            if ~isempty(app.Data.SessionSummary)
                mask = strcmp(app.Data.SessionSummary.person_id, personRow.person_id);
                rows = app.Data.SessionSummary(mask,:);
                lines = {};
                for r = 1:height(rows)
                    lines{end+1} = sprintf('%s | %s | %.0f min | mean HR %.0f | max HR %.0f', ...
                        rows.session_id{r}, rows.activity_type{r}, rows.duration_min(r), ...
                        rows.mean_heart_rate_bpm(r), rows.max_heart_rate_bpm(r)); %#ok<AGROW>
                end
                app.SumText.Value = lines;
            end
        end

        % Button pushed function: ImportPersonButton
        function ImportPersonButtonPushed(app, event)
            [f, p] = uigetfile('*.csv', 'Select wearable_person_metadata.csv');
            if isequal(f, 0); return; end
            app.Data.People = readtable(fullfile(p, f), 'TextType', 'string');
        end

        % Button pushed function: ImportSummaryButton
        function ImportSummaryButtonPushed(app, event)
            [f, p] = uigetfile('*.csv', 'Select wearable_session_summary.csv');
            if isequal(f, 0); return; end
            T = readtable(fullfile(p, f));
            if ismember('session_id', T.Properties.VariableNames)
                app.Data.SessionSummary = T;
            else
                uialert(app.UIFigure, 'Wrong file -- no session_id column found.', 'Wrong file selected');
            end
        end

        % Button pushed function: ImportMatButton
        function ImportMatButtonPushed(app, event)
                        [f, p] = uigetfile('*.mat', 'Select wearable_sensor_data.mat');
            if isequal(f, 0); return; end
            raw = load(fullfile(p, f));

            s = raw.sessions;
            if iscell(s); s = [s{:}]; end
            app.Data.Sessions = s;

            if isfield(raw, 'activity_met_reference')
                m = raw.activity_met_reference;
                if iscell(m); m = [m{:}]; end
                app.Data.METRef = struct2table(m);
            else
                activity_type = ["walking";"treadmill_running";"cycling";"elliptical"; ...
                    "weight_lifting";"bodyweight_training";"yoga"];
                typical_MET = [3.3; 9.8; 7.5; 5.0; 3.5; 6.0; 2.5];
                app.Data.METRef = table(activity_type, typical_MET);
            end

            labels = arrayfun(@(k) sprintf('%s - %s - %s', s(k).session_id, s(k).person_id, strrep(s(k).activity_type,'_',' ')), ...
                1:numel(s), 'UniformOutput', false);
            app.DropDown.Items = labels;
            app.DropDown.ItemsData = 1:numel(s);

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 39 640 442];

            % Create graphTab
            app.graphTab = uitab(app.TabGroup);
            app.graphTab.Title = 'Calories Graph';

            % Create caloriesAxes
            app.caloriesAxes = uiaxes(app.graphTab);
            title(app.caloriesAxes, 'Calories Burned (Cal) Vs. Type of Excercise')
            xlabel(app.caloriesAxes, 'Type of Excercise')
            ylabel(app.caloriesAxes, 'Calories Burned (Cal)')
            zlabel(app.caloriesAxes, 'Z')
            app.caloriesAxes.Position = [10 92 423 328];

            % Create DropDownLabel
            app.DropDownLabel = uilabel(app.graphTab);
            app.DropDownLabel.HorizontalAlignment = 'right';
            app.DropDownLabel.Position = [440 385 65 22];
            app.DropDownLabel.Text = 'Drop Down';

            % Create DropDown
            app.DropDown = uidropdown(app.graphTab);
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @DropDownValueChanged, true);
            app.DropDown.Position = [520 385 100 22];

            % Create ImportPersonButton
            app.ImportPersonButton = uibutton(app.graphTab, 'push');
            app.ImportPersonButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPersonButtonPushed, true);
            app.ImportPersonButton.Position = [520 289 100 22];
            app.ImportPersonButton.Text = 'Person Data';

            % Create ImportSummaryButton
            app.ImportSummaryButton = uibutton(app.graphTab, 'push');
            app.ImportSummaryButton.ButtonPushedFcn = createCallbackFcn(app, @ImportSummaryButtonPushed, true);
            app.ImportSummaryButton.Position = [520 214 100 22];
            app.ImportSummaryButton.Text = 'Session Data';

            % Create ImportMatButton
            app.ImportMatButton = uibutton(app.graphTab, 'push');
            app.ImportMatButton.ButtonPushedFcn = createCallbackFcn(app, @ImportMatButtonPushed, true);
            app.ImportMatButton.Position = [521 115 100 22];
            app.ImportMatButton.Text = 'Mat Data';

            % Create workoutRecTab
            app.workoutRecTab = uitab(app.TabGroup);
            app.workoutRecTab.Title = 'Workout Recommendation';

            % Create EffortLampLabel
            app.EffortLampLabel = uilabel(app.workoutRecTab);
            app.EffortLampLabel.HorizontalAlignment = 'right';
            app.EffortLampLabel.Position = [535 301 35 22];
            app.EffortLampLabel.Text = 'Lamp';

            % Create EffortLamp
            app.EffortLamp = uilamp(app.workoutRecTab);
            app.EffortLamp.Position = [585 301 20 20];

            % Create RecTextLabel
            app.RecTextLabel = uilabel(app.workoutRecTab);
            app.RecTextLabel.HorizontalAlignment = 'right';
            app.RecTextLabel.Position = [34 365 55 22];
            app.RecTextLabel.Text = 'Text Area';

            % Create RecText
            app.RecText = uitextarea(app.workoutRecTab);
            app.RecText.Position = [100 235 385 155];

            % Create WorkoutSumTab
            app.WorkoutSumTab = uitab(app.TabGroup);
            app.WorkoutSumTab.Title = 'Workout Summary';

            % Create TextArea2Label
            app.TextArea2Label = uilabel(app.WorkoutSumTab);
            app.TextArea2Label.HorizontalAlignment = 'right';
            app.TextArea2Label.Position = [34 346 62 22];
            app.TextArea2Label.Text = 'Text Area2';

            % Create SumText
            app.SumText = uitextarea(app.WorkoutSumTab);
            app.SumText.Position = [100 235 385 155];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end