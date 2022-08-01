clear all

% vector of subject numbers
subject = [802, 803, 804];
% main file name
file_name = "Version7_10Rules_deploy";
% USB drive name
main_file = input('What is the main drive name? ','s');
% total number of blocks
num_block = str2double(input('How many blocks? ','s'));
% number of trials
num_trials = str2double(input('How many events in total? ','s'));
% numnber of cues
num_cue = str2double(input('How many cues? ','s'));
% set numbr of trials per cue per block
num_trial = num_trials ./ num_block ./ num_cue ./ 2;
% ask if it wants a pause after each p
pau = input('Pause after each participant? Y/N:','s');


for sub = 1:length(subject);
    cd(strcat(main_file,':\Experiment_4\data\',file_name,'\results\p',num2str(subject(sub))));

    % SPIKE DATA

    % load the datafile starting at the TTL trigger
    data = importdata(strcat('data_',num2str(subject(sub)),'.mat'));

    % set number of blocks, trials, calibrations etc.
    num_cal = num_block - 1;
    block_tri = num_trial .* num_cue;

    % when I export the data from spike set it to 5000Hz and time shifted
    % divide n by 5 to set the value to ms

    % TTLs - cue
    run_ttl_cue = data.(strcat('data_',num2str(subject(sub)),'_Ch2')).values;
    change_ttl_cue = findchangepts(run_ttl_cue,'MaxNumChanges',num_trials .* 2);
    figure(100);
    plot(run_ttl_cue);
    hold on
    for n = 1:num_trials .* 2;
        xline(change_ttl_cue(n));
    end
    change_ttl_cue = change_ttl_cue ./ 5;

    % TTLs - target
    run_ttl_targ = data.(strcat('data_',num2str(subject(sub)),'_Ch3')).values;

    % correct for errors in the data
    if subject(sub) == 802;
        run_ttl_targ(685666:694931) = 0;
        run_ttl_targ(1957780:1978120) = 0;
        run_ttl_targ(2904700:2957920) = 0;
        run_ttl_targ(3383040:3401670) = 0;
        run_ttl_targ(3703030:3719000) = 0;
        run_ttl_targ(4180700:4200660) = 0;
        run_ttl_targ(4657040:4675660) = 0;
    end

    change_ttl_targ = findchangepts(run_ttl_targ,'MaxNumChanges',num_trials .* 2);
    figure(101);
    plot(run_ttl_targ);
    hold on
    for n = 1:num_trials .* 2;
        xline(change_ttl_targ(n));
    end
    change_ttl_targ = change_ttl_targ ./ 5;
    
    % TTLs - cue
    run_ttl_feed = data.(strcat('data_',num2str(subject(sub)),'_Ch4')).values;
    change_ttl_feed = findchangepts(run_ttl_feed,'MaxNumChanges',num_trials .* 2);
    figure(102);
    plot(run_ttl_feed);
    hold on
    for n = 1:num_trials .* 2;
        xline(change_ttl_feed(n));
    end
    change_ttl_feed = change_ttl_feed ./ 5;
    
    % TTLs - calibration
    cal_ttl = data.(strcat('data_',num2str(subject(sub)),'_Ch1')).values;
    change_cal = findchangepts(cal_ttl,'MaxNumChanges',num_cal .* 4);
    figure(103);
    plot(cal_ttl);
    hold on
    for n = 1:num_cal .* 4;
        xline(change_cal(n));
    end
    change_cal = change_cal ./ 5;

    % load the data
    data = importdata('RT_RESULTS2.txt');
    try
        data = data.textdata;
        data = str2double(data);
    end

    % clear the practise trials
    data(find(data(:,1) < 9),:) = [];
    
    % add in the event times
    clear n
    for n = 1:num_trials;
        % cue
        data(n,8) = change_ttl_cue(n .* 2 - 1) ./ 1000;
        data(n,9) = change_ttl_cue(n .* 2) ./ 1000;
        data(n,10) = (change_ttl_cue(n .* 2) - change_ttl_cue(n .* 2 - 1)) ./ 1000;
        % target
        data(n,11) = change_ttl_targ(n .* 2 - 1) ./ 1000;
        data(n,12) = change_ttl_targ(n .* 2) ./ 1000;
        data(n,13) = (change_ttl_targ(n .* 2) - change_ttl_targ(n .* 2 - 1)) ./ 1000;
        % feedback
        data(n,14) = change_ttl_feed(n .* 2 - 1) ./ 1000;
        data(n,15) = change_ttl_feed(n .* 2) ./ 1000;
        data(n,16) = (change_ttl_feed(n .* 2) - change_ttl_feed(n .* 2 - 1)) ./ 1000;
    end
    
    % add a column of zeros
    data(:,17:18) = 0;
    
    % add in calibration time
    clear n
    for n = 1:num_cal;
        design.cal_times(n,1) = change_cal(n .* 4 - 3) ./ 1000;
        design.cal_times(n,2) = change_cal(n .* 4) ./ 1000;
        design.cal_times(n,3) = (change_cal(n .* 4) - change_cal(n .* 4 - 3)) ./ 1000;
    end
    
    % separate into the exp and con trials
    exp.all = data(find(data(:,2) == 1),:);
    con.all = data(find(data(:,2) == 2),:);  




    clear n
    clear grand
    for n = 1:max(data(:,3));
        % create a folder name pertaining to the condition
        clear name
        name = strcat('con_',num2str(n));
        exp.(name) = exp.all(find(exp.all(:,3) == n),:);
        con.(name) = con.all(find(con.all(:,3) == n),:);
        
        % for each rule find the percentage of correct trials relative to
        % the number of non miss trials
        clear block
        for block = 1:num_block;
            grand(n,block) = length(find(exp.(name)((block .* (num_trials ./ num_block ./ num_cue ./ 2) - ((num_trials ./ num_block ./ num_cue ./ 2) - 1)):(block .* (num_trials ./ num_block ./ num_cue ./ 2)),6) == 2)) ./ ...
                length(find(exp.(name)((block .* (num_trials ./ num_block ./ num_cue ./ 2) - ((num_trials ./ num_block ./ num_cue ./ 2) - 1)):(block .* (num_trials ./ num_block ./ num_cue ./ 2)),6) > 0));
        end

        % plot results
        % EXPERIMENTAL
        figure(n);
        subplot(2,1,1);
        plot(exp.(name)(:,6));
        hold on
        title('Experimental');
        xlabel('Trials');
        ylabel('Outcome');
        ylim([0 2]);
        hold off
        figure(n);
        % CONTROL
        subplot(2,1,2);
        plot(con.(name)(:,6));
        hold on
        title('Control');
        xlabel('Trials');
        ylabel('Outcome');
        ylim([0 2]);
        hold off

        % work out the number of 1-2 trials
        if exp.(name)(2,6) == 2 & exp.(name)(1,6) == 1;
            try
                design.exp.cue12_1st(length(design.exp.cue12_1st(:,1)) + 1,:) = exp.(name)(1,:);
                exp.(name)(1,17) = 1;
                design.exp.cue12_2nd(length(design.exp.cue12_2nd(:,1)) + 1,:) = exp.(name)(2,:);
                exp.(name)(2,17) = 1;
            catch
                design.exp.cue12_1st = exp.(name)(1,:);
                exp.(name)(1,17) = 1;
                design.exp.cue12_2nd = exp.(name)(2,:);
                exp.(name)(2,17) = 1;
            end
        elseif exp.(name)(2,6) == 2 & exp.(name)(1,6) == 2;
            try
                design.exp.cue22_1st(length(design.exp.cue22_1st(:,1)) + 1,:) = exp.(name)(1,:);
                exp.(name)(1,17) = 1;
                design.exp.cue22_2nd(length(design.exp.cue22_2nd(:,1)) + 1,:) = exp.(name)(2,:);
                exp.(name)(2,17) = 1;
            catch
                design.exp.cue22_1st = exp.(name)(1,:);
                exp.(name)(1,17) = 1;
                design.exp.cue22_2nd = exp.(name)(2,:);
                exp.(name)(2,17) = 1;
            end
        end
        % cycle through the rest
        clear m
        for m = 3:length(exp.(name)(:,1));
            if exp.(name)(m,6) == 2 & exp.(name)(m-1,6) == 1 & exp.(name)(m-2,6) == 2;
                try
                    if exp.(name)(m - 1,17) == 0 & exp.(name)(m,17) == 0;
                        design.exp.cue12_1st(length(design.exp.cue12_1st(:,1)) + 1,:) = exp.(name)(m - 1,:);
                        design.exp.cue12_2nd(length(design.exp.cue12_2nd(:,1)) + 1,:) = exp.(name)(m,:);
                        exp.(name)(m - 1,17) = 1;
                        exp.(name)(m,17) = 1;
                    end
                catch
                    if exp.(name)(m - 1,17) == 0 & exp.(name)(m,17) == 0;
                        design.exp.cue12_1st = exp.(name)(m - 1,:);
                        design.exp.cue12_2nd = exp.(name)(m,:);
                        exp.(name)(m - 1,17) = 1;
                        exp.(name)(m,17) = 1;
                    end
                end
            % now look at 2-2 trials
            elseif exp.(name)(m,6) == 2 & exp.(name)(m-1,6) == 2 & exp.(name)(m-2,6) == 2;
                try
                    if exp.(name)(m - 1,17) == 0 & exp.(name)(m,17) == 0;
                        design.exp.cue22_1st(length(design.exp.cue22_1st(:,1)) + 1,:) = exp.(name)(m - 1,:);
                        design.exp.cue22_2nd(length(design.exp.cue22_2nd(:,1)) + 1,:) = exp.(name)(m,:);
                        exp.(name)(m - 1,17) = 1;
                        exp.(name)(m,17) = 1;
                    end
                catch
                    if exp.(name)(m - 1,17) == 0  & exp.(name)(m,17) == 0;
                        design.exp.cue22_1st = exp.(name)(m - 1,:);
                        design.exp.cue22_2nd = exp.(name)(m,:);
                        exp.(name)(m - 1,17) = 1;
                        exp.(name)(m,17) = 1;
                    end
                end
            end            
        end
        
        % now work through the remaining trials
        
        clear m
        for m = 1:length(exp.(name)(:,1));
            if exp.(name)(m,6) == 0 & exp.(name)(m,17) == 0;
                try
                    design.exp.cue0(length(design.exp.cue0(:,1)) + 1,:) = exp.(name)(m,:);
                    exp.(name)(m,18) = 1;
                catch
                    design.exp.cue0 = exp.(name)(m,:);
                    exp.(name)(m,18) = 1;
                end
                try
                    design.exp.cue1or0(length(design.exp.cue1or0(:,1)) + 1,:) = exp.(name)(m,:);
                catch
                    design.exp.cue1or0 = exp.(name)(1,:);
                end 
            elseif exp.(name)(m,6) == 1 & exp.(name)(m,17) == 0;
                try
                    design.exp.cue1(length(design.exp.cue1(:,1)) + 1,:) = exp.(name)(m,:);
                    exp.(name)(m,18) = 1;
                catch
                    design.exp.cue1 = exp.(name)(m,:);
                    exp.(name)(m,18) = 1;
                end
                try
                    design.exp.cue1or0(length(design.exp.cue1or0(:,1)) + 1,:) = exp.(name)(m,:);
                catch
                    design.exp.cue1or0 = exp.(name)(m,:);
                end
            elseif exp.(name)(m,6) == 2 & exp.(name)(m,17) == 0;
                try
                    design.exp.cue2(length(design.exp.cue2(:,1)) + 1,:) = exp.(name)(m,:);
                    exp.(name)(m,18) = 1;
                catch
                    design.exp.cue2 = exp.(name)(m,:);
                    exp.(name)(m,18) = 1;
                end
            end
        end
    
        % repeat for control
        % work out the number of 1-2 trials
        if con.(name)(2,6) == 2 & con.(name)(1,6) == 1;
            try
                design.con.cue12_1st(length(design.con.cue12_1st(:,1)) + 1,:) = con.(name)(1,:);
                con.(name)(1,17) = 1;
                design.con.cue12_2nd(length(design.con.cue12_2nd(:,1)) + 1,:) = con.(name)(2,:);
                con.(name)(2,17) = 1;
            catch
                design.con.cue12_1st = con.(name)(1,:);
                con.(name)(1,17) = 1;
                design.con.cue12_2nd = con.(name)(2,:);
                con.(name)(2,17) = 1;
            end
        elseif con.(name)(2,6) == 2 & con.(name)(1,6) == 2;
            try
                design.con.cue22_1st(length(design.con.cue22_1st(:,1)) + 1,:) = con.(name)(1,:);
                con.(name)(1,17) = 1;
                design.con.cue22_2nd(length(design.con.cue22_2nd(:,1)) + 1,:) = con.(name)(2,:);
                con.(name)(2,17) = 1;
            catch
                design.con.cue22_1st = con.(name)(1,:);
                con.(name)(1,17) = 1;
                design.con.cue22_2nd = con.(name)(2,:);
                con.(name)(2,17) = 1;
            end
        end
        % cycle through the rest
        clear m
        for m = 3:length(con.(name)(:,1));
            if con.(name)(m,6) == 2 & con.(name)(m-1,6) == 1 & con.(name)(m-2,6) == 2;
                try
                    if con.(name)(m - 1,17) == 0 & con.(name)(m,17) == 0;
                        design.con.cue12_1st(length(design.con.cue12_1st(:,1)) + 1,:) = con.(name)(m - 1,:);
                        design.con.cue12_2nd(length(design.con.cue12_2nd(:,1)) + 1,:) = con.(name)(m,:);
                        con.(name)(m - 1,17) = 1;
                        con.(name)(m,17) = 1;
                    end
                catch
                    if con.(name)(m - 1,17) == 0 & con.(name)(m,17) == 0;
                        design.con.cue12_1st = con.(name)(m - 1,:);
                        design.con.cue12_2nd = con.(name)(m,:);
                        con.(name)(m - 1,17) = 1;
                        con.(name)(m,17) = 1;
                    end
                end
            % now look at 2-2 trials
            elseif con.(name)(m,6) == 2 & con.(name)(m-1,6) == 2 & con.(name)(m-2,6) == 2;
                try
                    if con.(name)(m - 1,17) == 0 & con.(name)(m,17) == 0;
                        design.con.cue22_1st(length(design.con.cue22_1st(:,1)) + 1,:) = con.(name)(m - 1,:);
                        design.con.cue22_2nd(length(design.con.cue22_2nd(:,1)) + 1,:) = con.(name)(m,:);
                        con.(name)(m - 1,17) = 1;
                        con.(name)(m,17) = 1;
                    end
                catch
                    if con.(name)(m - 1,17) == 0  & con.(name)(m,17) == 0;
                        design.con.cue22_1st = con.(name)(m - 1,:);
                        design.con.cue22_2nd = con.(name)(m,:);
                        con.(name)(m - 1,17) = 1;
                        con.(name)(m,17) = 1;
                    end
                end
            end            
        end
        
        % now work through the remaining trials
        
        clear m
        for m = 1:length(con.(name)(:,1));
            if con.(name)(m,6) == 0 & con.(name)(m,17) == 0;
                try
                    design.con.cue0(length(design.con.cue0(:,1)) + 1,:) = con.(name)(m,:);
                    con.(name)(m,18) = 1;
                catch
                    design.con.cue0 = con.(name)(m,:);
                    con.(name)(m,18) = 1;
                end
                try
                    design.con.cue1or0(length(design.con.cue1or0(:,1)) + 1,:) = con.(name)(m,:);
                catch
                    design.con.cue1or0 = con.(name)(1,:);
                end 
            elseif con.(name)(m,6) == 1 & con.(name)(m,17) == 0;
                try
                    design.con.cue1(length(design.con.cue1(:,1)) + 1,:) = con.(name)(m,:);
                    con.(name)(m,18) = 1;
                catch
                    design.con.cue1 = con.(name)(m,:);
                    con.(name)(m,18) = 1;
                end
                try
                    design.con.cue1or0(length(design.con.cue1or0(:,1)) + 1,:) = con.(name)(m,:);
                catch
                    design.con.cue1or0 = con.(name)(m,:);
                end
            elseif con.(name)(m,6) == 2 & con.(name)(m,17) == 0;
                try
                    design.con.cue2(length(design.con.cue2(:,1)) + 1,:) = con.(name)(m,:);
                    con.(name)(m,18) = 1;
                catch
                    design.con.cue2 = con.(name)(m,:);
                    con.(name)(m,18) = 1;
                end
            end
        end
    end
    
    % sort the cue events in order of occurrence
    design.exp.cue12_1st = sortrows(design.exp.cue12_1st, 1);
    design.exp.cue12_2nd = sortrows(design.exp.cue12_2nd, 1);
    design.exp.cue22_1st = sortrows(design.exp.cue22_1st, 1);
    design.exp.cue22_2nd = sortrows(design.exp.cue22_2nd, 1);
    try
        design.exp.cue0 = sortrows(design.exp.cue0, 1);
    end
    design.exp.cue1 = sortrows(design.exp.cue1, 1);
    design.exp.cue1or0 = sortrows(design.exp.cue1or0, 1);
    design.exp.cue2 = sortrows(design.exp.cue2, 1);
    
    design.con.cue12_1st = sortrows(design.con.cue12_1st, 1);
    design.con.cue12_2nd = sortrows(design.con.cue12_2nd, 1);
    design.con.cue22_1st = sortrows(design.con.cue22_1st, 1);
    design.con.cue22_2nd = sortrows(design.con.cue22_2nd, 1);
    try
        design.con.cue0 = sortrows(design.con.cue0, 1);
    end
    design.con.cue1 = sortrows(design.con.cue1, 1);
    design.con.cue1or0 = sortrows(design.con.cue1or0, 1);
    design.con.cue2 = sortrows(design.con.cue2, 1);
    
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
    
    % work out mean performance across rules
    clear block
    for block = 1:num_block;
        grand(num_cue + 1,block) = mean(grand(1:num_cue,block));
    end
    
    % save the performance for this subject
    save grand grand
    save design design
    
        % check for non unique values
    clear a
    a = [design.exp.cue12_1st(:,1); design.exp.cue12_2nd(:,1); design.exp.cue22_1st(:,1); design.exp.cue22_2nd(:,1); design.exp.cue1or0(:,1); design.exp.cue2(:,1)];
    a = sortrows(a, 1);
    figure(200);
    hist(a,300)
    lengths(1) = length(a);

    clear a
    a = [design.con.cue12_1st(:,1); design.con.cue12_2nd(:,1); design.con.cue22_1st(:,1); design.con.cue22_2nd(:,1); design.con.cue1or0(:,1); design.con.cue2(:,1)];
    a = sortrows(a, 1);
    figure(201);
    hist(a,300)
    lengths(2) = length(a);
    
    try
        clear a
        a = [design.exp.cue12_1st(:,1); design.exp.cue12_2nd(:,1); design.exp.cue22_1st(:,1); design.exp.cue22_2nd(:,1); design.exp.cue1(:,1); design.exp.cue0(:,1); design.exp.cue2(:,1)];
        a = sortrows(a, 1);
        figure(202);
        hist(a,300)
        lengths(3) = length(a);
    end

    try
        clear a
        a = [design.con.cue12_1st(:,1); design.con.cue12_2nd(:,1); design.con.cue22_1st(:,1); design.con.cue22_2nd(:,1); design.con.cue1(:,1); design.con.cue0(:,1); design.con.cue2(:,1)];
        a = sortrows(a, 1);
        figure(203);
        hist(a,300)
        lengths(4) = length(a);
    end
    
    save lengths lengths
    
    % load up the saved file
    cd(strcat(main_file,':\Experiment_4\data\',file_name));
    if sub > 1;
        grand_tot = importdata('grand_tot.mat');
    end
    % add this subject to it
    grand_tot(sub,1:num_block) = grand(num_cue + 1,:);
    % add the total percentage of correct trials
    grand_tot(sub,num_block + 1) = length(find(data(:,6) == 2)) ./ num_trials;
    % add the total percentage of incorrect trials
    grand_tot(sub,num_block + 2) = length(find(data(:,6) == 1)) ./ num_trials;
    % add the total percentage of missed trials
    grand_tot(sub,num_block + 3) = 1 - (grand_tot(sub,num_block + 2) +  grand_tot(sub,num_block + 1))
    % and save
    save grand_tot grand_tot
    
    hold off
    
    clear a
    clear ans
    clear block
    clear block_tri
    clear cat_ttl
    clear change_cal
    clear change_ttl_cue
    clear change_ttl_feed
    clear change_ttl_targ
    clear con
    clear data
    clear design
    clear exp
    clear grand
    clear grand_tot
    clear lengths
    clear m
    clear n
    clear name
    clear run_ttl_cue
    clear run_ttl_feed
    clear run_ttl_targ

    
    if pau == 'Y'
        input('Ready for the next participant? If so press enter','s');
    end
end
