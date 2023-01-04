clear all

% vector of subject numbers
subject = [820];
% main file name
file_name = "Version8_10Rules_deploy2";
% using OneDrive?
drive = input('Are you using OneDrive? y/n','s');
% USB drive name
main_file = input('What is the main drive name? ','s');
% total number of blocks
num_block = str2double(input('How many blocks? ','s'));
% number of trials
num_trials = str2double(input('How many events in total? ','s'));
% number of cues
num_cue = str2double(input('How many cues? ','s'));
% set numbr of trials per cue per block
num_trial = num_trials ./ num_block ./ num_cue ./ 2;
% ask if it wants a pause after each p
pau = input('Pause after each participant? Y/N:','s');


for sub = 1:length(subject);
    
    if drive == 'y';
        cd(strcat(main_file,':\Users\mdanv\OneDrive\PhD_Stuff\Experiment_4\data\',file_name,'\results\p',num2str(subject(sub))));
    else
        cd(strcat(main_file,':\Experiment_4\data\',file_name,'\results\p',num2str(subject(sub))));
    end

    % DATAVIEWER TIMES
    % these are the messages from dataviewer isolated into a single column,
    % derived from analysis-messages(TXT and TIME)
    messages = importdata('messages.xlsx');
    % these are the message times from dataviewer isolated into a single column
    message_times = importdata('times.xlsx');
    % also load up the trial start times derived from analysis - trial report -
    % start_time. This tells us at what time in the eyetracker run the trial
    % started. Also put into a single column file.
    t_start = importdata('st_time.xlsx');
    
    % now look at the message file for the relevant indices of each cue type
    % CUE1
    cue1.a(:,1) = strcmp('TTL_cue1on',messages);
    cue1.final(:,1) = message_times(find(cue1.a(:,1) == 1));
    cue1.a(:,2) = strcmp('TTL_cue1off',messages);
    cue1.final(:,2) = message_times(find(cue1.a(:,2) == 1));
    cue1.final(:,3) = cue1.final(:,2) - cue1.final(:,1);

    % TARGET
    targ.a(:,1) = strcmp('TTL_targeton',messages);
    targ.final(:,1) = message_times(find(targ.a(:,1) == 1));
    % account for the fact that exp trials call this targetoff, and con
    % trial targoff
    targ.a(:,2) = strcmp('TTL_targetoff',messages);
    targ.a(:,3) = strcmp('TTL_targoff',messages);
    % add the two as it will be the actual time or a zero, so addition
    % selects the right time.
    targ.a(:,4) = targ.a(:,2) + targ.a(:,3);
    targ.final(:,2) = message_times(find(targ.a(:,4) == 1));
    targ.final(:,3) = targ.final(:,2) - targ.final(:,1);

    % FEEDBACK
    feed.a(:,1) = strcmp('TTL_feedon',messages);
    feed.final(:,1) = message_times(find(feed.a(:,1) == 1));
    feed.a(:,2) = strcmp('TTL_feedoff',messages);
    feed.final(:,2) = message_times(find(feed.a(:,2) == 1));
    feed.final(:,3) = feed.final(:,2) - feed.final(:,1);
    
    % START
    star.a = strcmp('trial_start',messages);
    star.final = message_times(find(star.a == 1));
    
    % look at when the MRI scanner started relative to the eyetracker running, based on the trial start time
    % for experimental trial 1, plus the delay which tells us when the first TTL
    % pulse was received.
    val = t_start(9) + star.final(1);
    
    % now make the trials cumulative and convert from milliseconds into seconds
    % also cut off the practise trials
    for n = 9:length(cue1.final);
        datav.cue(n-8,1) = ((t_start(n) + cue1.final(n,1)) - val) ./ 1000;
        datav.cue(n-8,2) = ((t_start(n) + cue1.final(n,2)) - val) ./ 1000;
        datav.targ(n-8,1) = ((t_start(n) + targ.final(n,1)) - val) ./ 1000;
        datav.targ(n-8,2) = ((t_start(n) + targ.final(n,2)) - val) ./ 1000;
        datav.feed(n-8,1) = ((t_start(n) + feed.final(n,1)) - val) ./ 1000;
        datav.feed(n-8,2) = ((t_start(n) + feed.final(n,2)) - val) ./ 1000;
    end
    
    % correct for a gap in scanning for participant 812 (the EPI scans were
    % compiled into one run, so the time difference between the final TTL
    % of the first run (TTL number 1100, the EPI file for which was not saved 
    % anyway hence 1099 EPI files in the first run) and the first TTL of the
    % new run is subtracted from all events from trial 181 onwards
    % (difference = 131.406 seconds)
    if subject(sub) == 812;
        datav.cue(181:300,1:2) = datav.cue(181:300,1:2) - 131.406;
        datav.targ(181:300,1:2) = datav.targ(181:300,1:2) - 131.406;
        datav.feed(181:300,1:2) = datav.feed(181:300,1:2) - 131.406;
    end
    
    
    % SPIKE DATA
    
    % set number of blocks, trials, calibrations etc.
    num_cal = num_block - 1;
    block_tri = num_trial .* num_cue;

    % make corrections for shortened trials
    if subject(sub) == 823;
        num_cal = 3;
        num_trials = 193;
        num_block = 3;
    end

    % load the datafile starting at the TTL trigger
    data = importdata(strcat('data_',num2str(subject(sub)),'.mat'));

    % when I export the data from spike set it to 5000Hz and time shifted
    % divide n by 5 to set the value to ms

    % TTLs - cue
    run_ttl_cue = data.(strcat('data_',num2str(subject(sub)),'_Ch2')).values;
    clear n
    clear change_ttl_cue
    spacing = 20;
    part = 0;
    pos = 0;
    high = max(run_ttl_cue) .* (1 - 0.05);
    low = min(run_ttl_cue) + (0.05 .* max(run_ttl_cue));
    for n = 1:length(run_ttl_cue);
        % if signal is higher than 5% of the minimum value and we are
        % running from low to high signal (part) which prevents repeated findings 
        % of upward change, and that the slope has an 
        % upward trend relative to a coordinate x units before (to prevent instantly 
        % finding a value below e.g. 95% of max signal, which would be prceived as a drop). 
        % Then we save the value as a positive change (onset)
        if run_ttl_cue(n) > low & part == 0 & run_ttl_cue(n) > run_ttl_cue(n-spacing);
            % save a new position
            pos = pos + 1;
            % inform the system we are now on the high signal part
            part = 1;
            change_ttl_cue(pos,1) = n;
        
        % conversely if the signal drops below 95% of the maximum value and
        % we are running along the high signal, and we see a drop
        % then we save the value as a negative change (offset)
        elseif run_ttl_cue(n) < high & part == 1 & run_ttl_cue(n) < run_ttl_cue(n-spacing);
            % inform the system we are now on the high signal part
            part = 0;
            change_ttl_cue(pos,2) = n;
        end
    end
    
    figure(1);
    plot(run_ttl_cue);
    hold on
    for n = 1:length(change_ttl_cue(:,1));
        xline(change_ttl_cue(n,1));
        xline(change_ttl_cue(n,2));
    end
    change_ttl_cue = change_ttl_cue ./ 5;
    spike.cue = change_ttl_cue ./ 1000;
    

    % TTLs - target
    run_ttl_targ = data.(strcat('data_',num2str(subject(sub)),'_Ch3')).values;

    clear n
    clear change_ttl_targ
    part = 0;
    pos = 0;
    high = max(run_ttl_targ) .* (1 - 0.05);
    low = min(run_ttl_targ) + (0.05 .* max(run_ttl_targ));
    for n = 1:length(run_ttl_targ);
        % if signal is higher than 5% of the minimum value and we are
        % running from low to high signal (part) which prevents repeated findings 
        % of upward change, and that the slope has an 
        % upward trend relative to a coordinate x units before (to prevent instantly 
        % finding a value below e.g. 95% of max signal, which would be prceived as a drop). 
        % Then we save the value as a positive change (onset)
        if run_ttl_targ(n) > low & part == 0 & run_ttl_targ(n) > run_ttl_targ(n-spacing);
            % save a new position
            pos = pos + 1;
            % inform the system we are now on the high signal part
            part = 1;
            change_ttl_targ(pos,1) = n;
        
        % conversely if the signal drops below 95% of the maximum value and
        % we are running along the high signal, and we see a drop
        % then we save the value as a negative change (offset)
        elseif run_ttl_targ(n) < high & part == 1 & run_ttl_targ(n) < run_ttl_targ(n-spacing);
            % inform the system we are now on the high signal part
            part = 0;
            change_ttl_targ(pos,2) = n;
        end
    end
    figure(2);
    plot(run_ttl_targ);
    hold on
    for n = 1:length(change_ttl_targ(:,1));
        xline(change_ttl_targ(n,1));
        xline(change_ttl_targ(n,2));
    end
    change_ttl_targ = change_ttl_targ ./ 5;
    spike.targ = change_ttl_targ ./ 1000;
    
    

    % TTLs - feed
    run_ttl_feed = data.(strcat('data_',num2str(subject(sub)),'_Ch4')).values;
    clear n
    clear change_ttl_feed
    part = 0;
    pos = 0;
    high = max(run_ttl_feed) .* (1 - 0.05);
    low = min(run_ttl_feed) + (0.05 .* max(run_ttl_feed));
    for n = 1:length(run_ttl_feed);
        % if signal is higher than 5% of the minimum value and we are
        % running from low to high signal (part) which prevents repeated findings 
        % of upward change, and that the slope has an 
        % upward trend relative to a coordinate x units before (to prevent instantly 
        % finding a value below e.g. 95% of max signal, which would be prceived as a drop). 
        % Then we save the value as a positive change (onset)
        if run_ttl_feed(n) > low & part == 0 & run_ttl_feed(n) > run_ttl_feed(n-spacing);
            % save a new position
            pos = pos + 1;
            % inform the system we are now on the high signal part
            part = 1;
            change_ttl_feed(pos,1) = n;
        
        % conversely if the signal drops below 95% of the maximum value and
        % we are running along the high signal, and we see a drop
        % then we save the value as a negative change (offset)
        elseif run_ttl_feed(n) < high & part == 1 & run_ttl_feed(n) < run_ttl_feed(n-spacing);
            % inform the system we are now on the high signal part
            part = 0;
            change_ttl_feed(pos,2) = n;
        end
    end
    figure(3);
    plot(run_ttl_feed);
    hold on
    for n = 1:length(change_ttl_feed(:,1));
        xline(change_ttl_feed(n,1));
        xline(change_ttl_feed(n,2));
    end
    change_ttl_feed = change_ttl_feed ./ 5;
    spike.feed = change_ttl_feed ./ 1000;

    % correct for the split in 812's data
    if subject(sub) == 812;
        spike.cue(181:300,1:2) = spike.cue(181:300,1:2) - 131.406;
        spike.targ(181:300,1:2) = spike.targ(181:300,1:2) - 131.406;
        spike.feed(181:300,1:2) = spike.feed(181:300,1:2) - 131.406;
    end

    % correct for dataviewer offset errors
    if subject(sub) == 810 | subject(sub) == 812 | subject(sub) == 813| subject(sub) == 819 | subject(sub) == 820 | subject(sub) == 823;
        clear shift
        % calculate the difference in the first event of each method, and
        % use this to correct dataviewer (as we are confident spike is
        % correct)
        shift = datav.cue(1,1) - spike.cue(1,1);
        datav.cue(:,:) = datav.cue(:,:) - shift;
        datav.targ(:,:) = datav.targ(:,:) - shift;
        datav.feed(:,:) = datav.feed(:,:) - shift;
    end
    
    % now compare this to dataviewer
    % make a comparable run for the dataviewer data - CUE
    datav.cuerun(1:length(run_ttl_cue)) = 0;
    spike.cuerun(1:length(run_ttl_cue)) = 0;
    % make a comparable run for the dataviewer data - TARGET
    datav.targrun(1:length(run_ttl_targ)) = 0;
    spike.targrun(1:length(run_ttl_cue)) = 0;
    % make a comparable run for the dataviewer data - FEEDBACK
    datav.feedrun(1:length(run_ttl_feed)) = 0;
    spike.feedrun(1:length(run_ttl_cue)) = 0;
    

    % now re-work the data to have different amplitudes so I can visually
    % compare. Look only at the shortest run so does not trip up
    for n = 1:min([length(datav.cue(:,1)) length(spike.cue(:,1))]);
        datav.cuerun(datav.cue(n,1) .* 5000:datav.cue(n,2) .* 5000) = 2.5;
        spike.cuerun(spike.cue(n,1) .* 5000:spike.cue(n,2) .* 5000) = 5;
    end
    
    for n = 1:min([length(datav.targ(:,1)) length(spike.targ(:,1))]);
        datav.targrun(datav.targ(n,1) .* 5000:datav.targ(n,2) .* 5000) = 2.5;
        spike.targrun(spike.targ(n,1) .* 5000:spike.targ(n,2) .* 5000) = 5;
    end

    for n = 1:min([length(datav.feed(:,1)) length(spike.feed(:,1))]);
        datav.feedrun(datav.feed(n,1) .* 5000:datav.feed(n,2) .* 5000) = 2.5;
        spike.feedrun(spike.feed(n,1) .* 5000:spike.feed(n,2) .* 5000) = 5;
    end


    % and plot
    a = figure(4);
    set(gcf,'Position',[60,60,1600 800]);
    subplot(3,1,1);
    plot(datav.cuerun);
    hold on
    plot(spike.cuerun);
    legend('Dataviewer','Spike');
    title('Cue Events');
    hold off
    subplot(3,1,2);
    plot(datav.targrun);
    hold on
    plot(spike.targrun);
    legend('Dataviewer','Spike');
    title('Target Events');
    hold off
    subplot(3,1,3);
    plot(datav.feedrun);
    hold on
    plot(spike.feedrun);
    legend('Dataviewer','Spike');
    title('Feedback Events');
    hold off
    saveas(a,'Runs','jpg');

    b = figure(5);
    set(gcf,'Position',[60,60,1600 800]);
    subplot(3,1,1);
    if subject(sub) == 815;
        plot(datav.cuerun(1:37000));
        hold on
        plot(spike.cuerun(1:37000));
    else
        plot(datav.cuerun(1:750000));
        hold on
        plot(spike.cuerun(1:750000));
    end
    legend('Dataviewer','Spike');
    title('Cue Events');
    hold off
    subplot(3,1,2);
    if subject(sub) == 815;
        plot(datav.targrun(1:37000));
        hold on
        plot(spike.targrun(1:37000));
    else
        plot(datav.targrun(1:750000));
        hold on
        plot(spike.targrun(1:750000));
    end
    legend('Dataviewer','Spike');
    title('Target Events');
    hold off
    subplot(3,1,3);
    if subject(sub) == 815;
        plot(datav.feedrun(1:37000));
        hold on
        plot(spike.feedrun(1:37000));
    else
        plot(datav.feedrun(1:750000));
        hold on
        plot(spike.feedrun(1:750000));
    end
    legend('Dataviewer','Spike');
    title('Feedback Events');
    hold off
    saveas(b,'Runs zoomed','jpg');

   
    % include a matrix of cal-rest block onset/offset differences from
    % surrounding trials. For example, for rest block one rest onset is 1516ms after feedback
    % offset on trial 60, and rest offset is 458ms before cue onset on
    % trial 61 (based on programmed event timings and trial length.
    cal_mat = [1.516 .772 1.146 .150;
        .458 .540 1.737 .786];
    % make a run
    cal_ttl(1:ceil(length(run_ttl_cue)) ./ 5000) = 0;
    % work out the on and off times and apply to run
    clear n
    for n = 1:num_cal;
        change_cal((n .* 2) - 1) = datav.feed(60 .* n) + cal_mat(1,n);
        change_cal(n .* 2) = datav.cue((60 .* n) + 1) - cal_mat(2,n);
        cal_ttl(ceil(change_cal((n .* 2) - 1)):ceil(change_cal(n .* 2))) = 1;
    end
    % plot
    c = figure(6);
    set(gcf,'Position',[60,60,1600 800]);
    plot(cal_ttl);
    hold on
    clear n
    for n = 1:num_cal .* 2;
        xline(change_cal(n));
    end
    saveas(c,'Calibrations','jpg');




    % load the data
    data = importdata('RT_RESULTS2.txt');
    try
        data = data.textdata;
        data = str2double(data);
    end

    % clear the practise trials
    data(find(data(:,1) < 9),:) = [];

    % trim trials where not needed or problematic. 823 has 13 trials that
    % have no control comparison, 812 had a break in scanning, 820 had high
    % head motion.
    if subject(sub) == 823;
        data(181:193,:) = [];
        num_trials = 180;
        num_block = 3;
    elseif subject(sub) == 812;
        data(181:300,:) = [];
        num_trials = 180;
        num_block = 3;
        spike.cue(181:300,:) = [];
        spike.targ(181:300,:) = [];
        spike.feed(181:300,:) = [];
    elseif subject(sub) == 820;
        data(241:300,:) = [];
        num_trials = 240;
        num_block = 4;
        spike.cue(241:300,:) = [];
        spike.targ(241:300,:) = [];
        spike.feed(241:300,:) = [];
    end
    
    % add in the event times
    clear n
    for n = 1:num_trials;
        % cue
        data(n,8) = datav.cue(n,1);
        data(n,9) = datav.cue(n,2);
        data(n,10) = datav.cue(n,2) - datav.cue(n,1);
        % target
        data(n,11) = datav.targ(n,1);
        data(n,12) = datav.targ(n,2);
        data(n,13) = datav.targ(n,2) - datav.targ(n,1);
        % feedback
        data(n,14) = datav.feed(n,1);
        data(n,15) = datav.feed(n,2);
        data(n,16) = datav.feed(n,2) - datav.feed(n,1);
    end
    
    % add a column of zeros
    data(:,17:18) = 0;

       
    % also plot the durations of events to see how well it works
    if subject(sub) == 823 | subject(sub) == 812;
        run = [1:180];
    elseif subject(sub) == 820;
        run = [1:240];
    else
        run = [1:300];
    end
    d = figure(7);
    set(gcf,'Position',[60,60,1600 800]);
    subplot(3,1,1);
    scatter(run,data(:,10));
    xlabel('Trial');
    ylabel('Duration (secs)');
    title('Cue');
    
    subplot(3,1,2);
    scatter(run,data(:,13));
    xlabel('Trial');
    ylabel('Duration (secs)');
    title('Target');
    
    subplot(3,1,3);
    scatter(run,data(:,16));
    xlabel('Trial');
    ylabel('Duration (secs)');
    title('Feedback');

    saveas(d,'DV Durations','jpg');
    

    
    
    % method differences
    % first cue onsets
    diff.onset(1,1) = datav.cue(1,1);
    diff.onset(1,2) = spike.cue(1,1);
    diff.onset(1,3) = diff.onset(1,2) - diff.onset(1,1);
    % first target onsets
    diff.onset(3,1) = datav.targ(1,1);
    diff.onset(3,2) = spike.targ(1,1);
    diff.onset(3,3) = diff.onset(3,2) - diff.onset(3,1);
    % first feedback onsets
    diff.onset(5,1) = datav.feed(1,1);
    diff.onset(5,2) = spike.feed(1,1);
    diff.onset(5,3) = diff.onset(5,2) - diff.onset(5,1);
    
    % as a result of short spike files....
    if subject(sub) ~= 815 & subject(sub) ~= 808;
        % final cue onsets
        diff.onset(2,1) = datav.cue(length(datav.cue(:,1)),1);
        diff.onset(2,2) = spike.cue(length(spike.cue(:,1)),1);
        diff.onset(2,3) = diff.onset(2,2) - diff.onset(2,1);
        % final target onsets
        diff.onset(4,1) = datav.targ(length(datav.targ(:,1)),1);
        diff.onset(4,2) = spike.targ(length(spike.targ(:,1)),1);
        diff.onset(4,3) = diff.onset(4,2) - diff.onset(4,1);
        % final feedback onsets
        diff.onset(6,1) = datav.feed(length(datav.feed(:,1)),1);
        diff.onset(6,2) = spike.feed(length(spike.feed(:,1)),1);
        diff.onset(6,3) = diff.onset(6,2) - diff.onset(6,1);
    end

    % first cue durations
    diff.duration(1,1) = datav.cue(1,2) - datav.cue(1,1);
    diff.duration(1,2) = spike.cue(1,2) - spike.cue(1,1);
    diff.duration(1,3) = diff.duration(1,2) - diff.duration(1,1);
    % first target durations
    diff.duration(3,1) = datav.targ(1,2) - datav.targ(1,1);
    diff.duration(3,2) = spike.targ(1,2) - spike.targ(1,1);
    diff.duration(3,3) = diff.duration(3,2) - diff.duration(3,1);
    % first feedback durations
    diff.duration(5,1) = datav.feed(1,2) - datav.feed(1,1);
    diff.duration(5,2) = spike.feed(1,2) - spike.feed(1,1);
    diff.duration(5,3) = diff.duration(5,2) - diff.duration(5,1);
    
    % as a result of short spike files.....
    if subject(sub) ~= 815 & subject(sub) ~= 808;
        % final cue durations
        diff.duration(2,1) = datav.cue(length(datav.cue(:,1)),2) - datav.cue(length(datav.cue(:,1)),1);
        diff.duration(2,2) = spike.cue(length(spike.cue(:,1)),2) - spike.cue(length(spike.cue(:,1)),1);;
        diff.duration(2,3) = diff.duration(2,2) - diff.duration(2,1);
        % final target durations
        diff.duration(4,1) = datav.targ(length(datav.targ(:,1)),2) - datav.targ(length(datav.targ(:,1)),1);
        diff.duration(4,2) = spike.targ(length(spike.targ(:,1)),2) - spike.targ(length(spike.targ(:,1)),1);
        diff.duration(4,3) = diff.duration(4,2) - diff.duration(4,1);
        % final feedback durations
        diff.duration(6,1) = datav.feed(length(datav.feed(:,1)),2) - datav.feed(length(datav.feed(:,1)),1);
        diff.duration(6,2) = spike.feed(length(spike.feed(:,1)),2) - spike.feed(length(spike.feed(:,1)),1);
        diff.duration(6,3) = diff.duration(6,2) - diff.duration(6,1);
    
        % check drift
        diff.drift(1,1) = diff.onset(2,3) - diff.onset(1,3);
        diff.drift(3,1) = diff.onset(4,3) - diff.onset(3,3);
        diff.drift(5,1) = diff.onset(6,3) - diff.onset(5,3);
    end

    save diff diff


    
    % all data collects everything for the main results file and saves for
    % each p
    clear all_data
    all_data(1,67) = min(data(:,10));
    all_data(1,68) = max(data(:,10));
    all_data(1,69) = min(data(:,13));
    all_data(1,70) = max(data(:,13));
    all_data(1,71) = min(data(:,16));
    all_data(1,72) = max(data(:,16));


    % add in calibration time
    clear n
    for n = 1:num_cal;
        design.cal_times(n,1) = change_cal(n .* 2 - 1);
        design.cal_times(n,2) = change_cal(n .* 2);
        design.cal_times(n,3) = (change_cal(n .* 2) - change_cal(n .* 2 - 1));
    end

    
    % separate into the exp and con trials
    exp.all = data(find(data(:,2) == 1),:);
    con.all = data(find(data(:,2) == 2),:);
    exp.all(:,19) = 0;
    con.all(:,19) = 0;

    % save the key data pertaining to type of trials
    % first find the percentage of correct trials within each block,
    % relative to non miss trials
    clear x
    for x = 1:num_block;
        all_data(1,x) = length(find(exp.all(1 + ((num_trials ./ num_block ./ 2) .* (x - 1)):x .* (num_trials ./ num_block ./ 2),6) == 2)) ...
            ./ length(find(exp.all(1 + ((num_trials ./ num_block ./ 2) .* (x - 1)):x .* (num_trials ./ num_block ./ 2),6) > 0));
    end

    % now look at gross data
    all_data(1,6) = length(find(exp.all(:,6) == 2)) ./ length(exp.all(:,6));
    all_data(1,7) = length(find(exp.all(:,6) == 1)) ./ length(exp.all(:,6));
    all_data(1,8) = length(find(exp.all(:,6) == 0)) ./ length(exp.all(:,6));
    % for control I look for actual target values to be zero, as the
    % feedback itself is not based on real performance.
    all_data(1,9) = length(find(con.all(:,5) == 0)) ./ length(con.all(:,6));



    % work through each individual rule (percentage correct relative to
    % number of non missed trials
    clear cue
    count = 0;
    for cue = 1:num_cue;
        clear x
        for x = 1:num_block;
            count = count + 1;
            all_data(1,9 + count) = length(find(exp.all(1 + ((num_trials ./ num_block ./ 2) .* (x - 1)):x .* (num_trials ./ num_block ./ 2),6) == 2 & ...
                exp.all(1 + ((num_trials ./ num_block ./ 2) .* (x - 1)):x .* (num_trials ./ num_block ./ 2),3) == cue)) ...
            ./ length(find(exp.all(1 + ((num_trials ./ num_block ./ 2) .* (x - 1)):x .* (num_trials ./ num_block ./ 2),6) > 0 & ...
                exp.all(1 + ((num_trials ./ num_block ./ 2) .* (x - 1)):x .* (num_trials ./ num_block ./ 2),3) == cue));
        end
    end
    

    clear n
    clear grand
    % cycle through each individual cue
    for n = 1:max(data(:,3));
        % create a folder name pertaining to the condition and cue
        clear name
        name = strcat('con_',num2str(n));
        exp.(name) = exp.all(find(exp.all(:,3) == n),:);
        con.(name) = con.all(find(con.all(:,3) == n),:);
        

        % plot results
        % EXPERIMENTAL
        figure(n+100);
        subplot(2,1,1);
        plot(exp.(name)(:,6));
        hold on
        title('Experimental');
        xlabel('Trials');
        ylabel('Outcome');
        ylim([0 2]);
        hold off
        figure(n+100);
        % CONTROL
        subplot(2,1,2);
        plot(con.(name)(:,6));
        hold on
        title('Control');
        xlabel('Trials');
        ylabel('Outcome');
        ylim([0 2]);
        hold off

      

        % now make an alternative dataset if we do a different analysis.
        % Here I cluster all correct preceded by correct, then all
        % incorrect, then all others (so missed and correct preceded by 0
        % or 1).
        % EXP
        if exp.(name)(1,6) == 1;
            try
                design.exp.cue1(length(design.exp.cue1(:,1)) + 1,:) = exp.(name)(1,:);
            catch
                design.exp.cue1 = exp.(name)(1,:);
            end
        % key here is the first trial is either categorically wrong, a
        % miss, or a guess but correct. Miss and guessed correct is always
        % put in junk.
        else
            try
                design.exp.cuejunk(length(design.exp.cuejunk(:,1)) + 1,:) = exp.(name)(1,:);
            catch
                design.exp.cuejunk = exp.(name)(1,:);
            end
        end
        % cycle through rest
        clear m
        for m = 2:length(exp.(name)(:,1));
            % if correct followed by correct then counted as an informed
            % trial.
            if exp.(name)(m,6) == 2 & exp.(name)(m-1,6) == 2;
                try
                    design.exp.cue2(length(design.exp.cue2(:,1)) + 1,:) = exp.(name)(m,:);
                catch
                    design.exp.cue2 = exp.(name)(m,:);
                end
            elseif exp.(name)(m,6) == 1;
                try
                    design.exp.cue1(length(design.exp.cue1(:,1)) + 1,:) = exp.(name)(m,:);
                catch
                    design.exp.cue1 = exp.(name)(m,:);
                end
            else
                try
                    design.exp.cuejunk(length(design.exp.cuejunk(:,1)) + 1,:) = exp.(name)(m,:);
                catch
                    design.exp.cuejunk = exp.(name)(m,:);
                end
            end
        end


        % con
        if con.(name)(1,6) == 1;
            try
                design.con.cue1(length(design.con.cue1(:,1)) + 1,:) = con.(name)(1,:);
            catch
                design.con.cue1 = con.(name)(1,:);
            end
        % key here is the first trial is either categorically wrong, a
        % miss, or a guess but correct. Miss and guessed correct is always
        % put in junk.
        else
            try
                design.con.cuejunk(length(design.con.cuejunk(:,1)) + 1,:) = con.(name)(1,:);
            catch
                design.con.cuejunk = con.(name)(1,:);
            end
        end
        % cycle through rest
        clear m
        for m = 2:length(con.(name)(:,1));
            % if correct followed by correct then counted as an informed
            % trial.
            if con.(name)(m,6) == 2 & con.(name)(m-1,6) == 2;
                try
                    design.con.cue2(length(design.con.cue2(:,1)) + 1,:) = con.(name)(m,:);
                catch
                    design.con.cue2 = con.(name)(m,:);
                end
            elseif con.(name)(m,6) == 1;
                try
                    design.con.cue1(length(design.con.cue1(:,1)) + 1,:) = con.(name)(m,:);
                catch
                    design.con.cue1 = con.(name)(m,:);
                end
            else
                try
                    design.con.cuejunk(length(design.con.cuejunk(:,1)) + 1,:) = con.(name)(m,:);
                catch
                    design.con.cuejunk = con.(name)(m,:);
                end
            end
        end
    end
    % sort rows
    design.exp.cue1 = sortrows(design.exp.cue1, 1);
    design.exp.cue2 = sortrows(design.exp.cue2, 1);
    design.exp.cuejunk = sortrows(design.exp.cuejunk, 1);
    design.con.cue1 = sortrows(design.con.cue1, 1);
    design.con.cue2 = sortrows(design.con.cue2, 1);
    design.con.cuejunk = sortrows(design.con.cuejunk, 1);


       
    % EXP
    % work through targets based upon position of target selected
    design.exp.targ1 = exp.all(find(exp.all(:,5) == 1),:);
    design.exp.targ2 = exp.all(find(exp.all(:,5) == 2),:);
    design.exp.targ3 = exp.all(find(exp.all(:,5) == 3),:);
    % try to save missed cases
    try
        design.exp.targ0 = exp.all(find(exp.all(:,5) == 0),:);
    end
    % also save a selection of missed or position 1
    design.exp.targ1or0 = exp.all(find(exp.all(:,5) < 2),:);
    
    % CON
    design.con.targ1 = con.all(find(con.all(:,5) == 1),:);
    design.con.targ2 = con.all(find(con.all(:,5) == 2),:);
    design.con.targ3 = con.all(find(con.all(:,5) == 3),:);
    % try to save missed cases
    try
        design.con.targ0 = con.all(find(con.all(:,5) == 0),:);
    end
    % also save a selection of missed or position 1
    design.con.targ1or0 = con.all(find(con.all(:,5) < 2),:);
    
    % COMBINED
    design.combined.targ1 = data(find(data(:,5) == 1),:);
    design.combined.targ2 = data(find(data(:,5) == 2),:);
    design.combined.targ3 = data(find(data(:,5) == 3),:);
    % try to save missed cases
    try
        design.combined.targ0 = data(find(data(:,5) == 0),:);
    end
    % also save a selection of missed or position 1
    design.combined.targ1or0 = data(find(data(:,5) < 2),:);
    
    
    % now work through feedback
    % EXP
    design.exp.feed2 = exp.all(find(exp.all(:,6) == 2),:);
    design.exp.feed1 = exp.all(find(exp.all(:,6) == 1),:);
    try
        design.exp.feed0 = exp.all(find(exp.all(:,6) == 0),:);
    end
    design.exp.feed1or0 = exp.all(find(exp.all(:,6) < 2),:);
    
    % CON
    design.con.feed2 = con.all(find(con.all(:,6) == 2),:);
    design.con.feed1 = con.all(find(con.all(:,6) == 1),:);
    try
        design.con.feed0 = con.all(find(con.all(:,6) == 0),:);
    end
    design.con.feed1or0 = con.all(find(con.all(:,6) < 2),:);
    
    % COMBINED
    design.combined.feed2 = data(find(data(:,6) == 2),:);
    design.combined.feed1 = data(find(data(:,6) == 1),:);
    try
        design.combined.feed0 = data(find(data(:,6) == 0),:);
    end
    design.combined.feed1or0 = data(find(data(:,6) < 2),:);
    

    


    % save the number of events in my main regressor
    try
        all_data(1,65) = length(design.exp.cue12_1st(:,1));
    catch
        all_data(1,65) = 0;
    end
    try
        all_data(1,66) = length(design.exp.cue22_1st(:,1));
    catch
        all_data(1,66) = 0;
    end

    % save subject number with design data
    design.sub = subject(sub);

    save design2 design
    
    % check for non unique values
    clear a
    a = [design.exp.cue1(:,1); design.exp.cue2(:,1); design.exp.cuejunk(:,1); design.con.cue1(:,1); design.con.cue2(:,1); design.con.cuejunk(:,1)];
    a = sortrows(a, 1);
    figure(8);
    hist(a,300)
    lengths(1) = length(a);

    

    all_data(1,73) = subject(sub);

    save all_data2 all_data
    save lengths2 lengths
    if pau == 'Y'
        input('Ready for the next participant? If so press enter','s');
    end
       
    hold off
    
    clear a
    clear b
    clear c
    clear d
    clear all_data
    clear ans
    clear block
    clear block_tri
    clear cal_ttl
    clear change_cal
    clear change_ttl_cue
    clear change_ttl_feed
    clear change_ttl_targ
    clear con
    clear cue1
    clear data
    clear datav
    clear design
    clear diff
    clear exp
    clear feed
    clear high
    clear lengths
    clear low
    clear m
    clear messages
    clear message_times
    clear n
    clear name
    clear run
    clear run_ttl_cue
    clear run_ttl_feed
    clear run_ttl_targ
    clear spike
    clear star
    clear t_start
    clear targ
    clear var
    clear x

    set (groot, 'ShowHiddenHandles', 'on' );
    c = get (groot, 'Children' )
    delete (c)
end
