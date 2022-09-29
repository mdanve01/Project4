% Has an update that saves the jitter in its original format so it can
% be checked, and when we jitter over 2 TRs it moves the 2nd TRs jitter so 
% samples sit in the middle of the samples in the first TR to keep it
% uniform. Jitters are then plotted so we can ensure they make sense.

% This has a simplified structure to ensure the while loop for the main
% body does not repeat the jitter creation process.

clear all
cd('F:/Experiment_4/create_run');

% set a counter
counter = 1;

% set the number of cue variants
data.num_cues = 10;

% set the number of blocks
data.tot_num_blocks = 5;

% set the number of targets
data.num_targets = 3;

% set the multiplier by which I generate the number of trials
data.multiplier = 3;

% set the correlation threshold below which we accept the design
data.rep_thresh = 0.01;

% generate a list of equidistant events for each condition (x =
% experimental, c = control). The number of experimental
% trials must be divisible by the number of rules, also the number of
% control trials must be divisible by the number of cues, the number of
% targets (less important) and the number of blocks
data.numtri_x = data.num_cues .* data.tot_num_blocks .* data.multiplier
data.numtri_c = data.num_cues .* data.tot_num_blocks .* data.multiplier

% ensure this matches the create_timings_exp.m file
data.tot_num_trials = data.numtri_x + data.numtri_c;

% set length of events
data.cue_spec = 250;
data.targ_spec = 1250;
data.feed_spec = 250;

% set the delay from start of TR to first event
data.del.cue = 0;
data.del.targ = 350;
data.del.feed = 0;

% set correlation r value threshold (nothing should be above this, set 
% this to .10 as that is a small effect)
data.r_thresh = 0.1;

% set tr
data.tr = 1760;

% set the number of TRs the cue stimuli are jittered over
data.num_tr.cue = 1;
data.num_tr.targ = 2;
data.num_tr.feed = 2;

% set start times
data.cue_start = 0 + data.del.cue;
data.targ_start = data.cue_start + (data.tr .* data.num_tr.cue) + data.del.targ - data.del.cue;
data.feed_start = data.targ_start + (data.tr .* data.num_tr.targ) + data.del.feed - data.del.cue - data.del.targ;

% set trial length in seconds
data.trilen = (data.tr ./ 1000) .* (data.num_tr.cue + data.num_tr.targ + data.num_tr.feed);

% set the jitter reduction, so if is a 2000ms window but want a jitter over
% 1750ms, then set to 250.
data.jitter.cue = 0;
data.jitter.targ = 1250;
data.jitter.feed = 1000;

% set an offset, so for example if this is 10, that means that the first 10
% percent of trials within a block are less likely to include controls, and the last 10
% percent are less likely to include experimental trials
data.offset = 32;

% set expected performance once see the right answer
data.performance = 0.50

% CHECK DIVISIBILITY %
% checks I can spread trials equally over blocks
data.checkx = (data.numtri_x ./ data.tot_num_blocks) ./ data.num_cues;
data.checkc = (data.numtri_c ./ data.tot_num_blocks) ./ data.num_cues;
% checks I can spread trials equally over targets (for control)
data.check_targx = data.numtri_x ./ data.num_targets;
data.check_targc = data.numtri_c ./ data.num_targets;
% I then use mod to establish if the modulo of the number is zero, if it is
% then it must be an integer, which I need
if mod(data.checkx,1) ~= 0 | mod(data.checkc,1) ~= 0 | mod(data.check_targx,1) ~= 0 | mod(data.check_targc,1) ~= 0;
    "NOT DIVISIBLE!"
    else
    "DIVISIBLE, CRACK ON"
end

% set the number of regressors in the final design matrix
data.num_regressors = 22;


%%%% EXPERIMENTAL %%%%

% prep the jitter. Each is jittered over 1750ms, but this can vary
clear n
time.jump_cuex = ((data.tr .* data.num_tr.cue) - data.jitter.cue - data.del.cue) ./ data.numtri_x;
time.jump_targx = ((data.tr .* data.num_tr.targ) - data.jitter.targ - data.del.targ) ./ data.numtri_x;
time.jump_feedx = ((data.tr .* data.num_tr.feed) - data.jitter.feed - data.del.feed) ./ data.numtri_x;

% loop through and create timings
for n = 1:data.numtri_x;
    time.cue1_x(n,2) = (time.jump_cuex .* n) + data.cue_start;
end
% if multiple TRs being jittered over ensure sampling is good
if data.num_tr.cue > 1;
    clear a
    a = (time.cue1_x(1,2) ./ 2) - (time.cue1_x(find(time.cue1_x(:,2) > data.tr,1),2) - data.tr);
    if a < time.cue1_x(1,2) ./ 2;
        time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) = time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) + a;
    else
        time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) = time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) - a;
    end
end
% now add the attributes:
% column 2 = cue timing
% column 3 = target timing
% column 5 = cue type
% column 7 = experimental condition (1 = x, 2 = c)
time.cue1_x(:,5) = 1;
clear n
for n = 1:data.numtri_x ./ data.num_cues;
    clear y
    y = n .* data.num_cues;
    time.cue1_x(y,5) = data.num_cues;
    if data.num_cues > 2;
        clear x
        for x = 1:data.num_cues - 2;
            time.cue1_x(y-x,5) = data.num_cues - x;
        end
    end
end
time.cue1_x(:,7) = 1;
% under timing save the original jitter so it can be checked
timing.origcue1_x = time.cue1_x;

% create times for targets
clear n
for n = 1:data.numtri_x;
    time.targ_x(n,:) = (time.jump_targx .* n) + data.targ_start;
end
% if multiple TRs being jittered over ensure sampling is good
if data.num_tr.targ > 1;
    clear a
    a = ((time.targ_x(1,1) - data.targ_start) ./ 2) - (time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1),1) - (data.tr + data.targ_start));
    if a < (time.targ_x(1,1) - data.targ_start) ./ 2;
        time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) = time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) + a;
    else
        time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) = time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) - a;
    end
end
timing.origtarg_x = time.targ_x;

% create times for feedback
clear n
for n = 1:data.numtri_x;
    time.feed_x(n,:) = (time.jump_feedx .* n) + data.feed_start;
end
% if multiple TRs being jittered over ensure sampling is good
if data.num_tr.feed > 1;
    clear a
    a = ((time.feed_x(1,1) - data.feed_start) ./ 2) - (time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1),1) - (data.tr + data.feed_start));
    if a < (time.feed_x(1,1) - data.feed_start) ./ 2;
        time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) = time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) + a;
    else
        time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) = time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) - a;
    end
end
timing.origfeed_x = time.feed_x;


% randomise
time.cue1_x(:,1) = rand(1,data.numtri_x);
time.cue1_x = sortrows(time.cue1_x,1);
time.targ_x(:,2) = rand(1,data.numtri_x);
time.targ_x = sortrows(time.targ_x,2);
time.feed_x(:,2) = rand(1,data.numtri_x);
time.feed_x = sortrows(time.feed_x,2);
clear RHO1
clear RHO2
clear RHO3
[RHO1,PVAL1] = corr(time.cue1_x(:,2),time.targ_x(:,1));
[RHO2,PVAL2] = corr(time.cue1_x(:,2),time.feed_x(:,1));
[RHO3,PVAL3] = corr(time.targ_x(:,1),time.feed_x(:,1));
time.r.x = max([abs(RHO1) abs(RHO2) abs(RHO3)]);

% loops through until the cue and target onset times are maximally
% uncorrelated
while time.r.x > data.r_thresh;
    % randomise
    time.cue1_x(:,1) = rand(1,data.numtri_x);
    time.cue1_x = sortrows(time.cue1_x,1);
    time.targ_x(:,2) = rand(1,data.numtri_x);
    time.targ_x = sortrows(time.targ_x,2);
    time.feed_x(:,2) = rand(1,data.numtri_x);
    time.feed_x = sortrows(time.feed_x,2);
    clear RHO1
    clear RHO2
    clear RHO3
    [RHO1,PVAL1] = corr(time.cue1_x(:,2),time.targ_x(:,1));
    [RHO2,PVAL2] = corr(time.cue1_x(:,2),time.feed_x(:,1));
    [RHO3,PVAL3] = corr(time.targ_x(:,1),time.feed_x(:,1));
    time.r.x = max([abs(RHO1) abs(RHO2) abs(RHO3)]);

end

% add target times to the main list
time.x = time.cue1_x;
time.x(:,1) = 0;
time.x(:,3) = time.targ_x(:,1);
time.x(:,4) = time.feed_x(:,1);

% create zero columns for later stacking
time.x(:,8:9) = 0;

"experimental correlations fixed"





%%%% CONTROL %%%%

% prep the jitter. Each is jittered over 1750ms, but this can vary
clear n
time.jump_cuec = ((data.tr .* data.num_tr.cue) - data.jitter.cue - data.del.cue) ./ data.numtri_c;
time.jump_targc = ((data.tr .* data.num_tr.targ) - data.jitter.targ - data.del.targ) ./ data.numtri_c;
time.jump_feedc = ((data.tr .* data.num_tr.feed) - data.jitter.feed - data.del.feed) ./ data.numtri_c;

% loop through and create timings
for n = 1:data.numtri_c;
    time.cue1_c(n,2) = (time.jump_cuec .* n) + data.cue_start;
end
% if multiple TRs being jittered over ensure sampling is good
if data.num_tr.cue > 1;
    clear a
    a = (time.cue1_c(1,2) ./ 2) - (time.cue1_c(find(time.cue1_c(:,2) > data.tr,1),2) - data.tr);
    if a < time.cue1_c(1,2) ./ 2;
        time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) = time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) + a;
    else
        time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) = time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) - a;
    end
end
% now add the attributes:
% column 2 = cue timing
% column 3 = target timing
% column 5 = cue type
% column 7 = experimental condition (1 = x, 2 = c)
time.cue1_c(:,5) = 1;
clear n
for n = 1:data.numtri_c ./ data.num_cues;
    clear y
    y = n .* data.num_cues;
    time.cue1_c(y,5) = data.num_cues;
    if data.num_cues > 2;
        clear x
        for x = 1:data.num_cues - 2;
            time.cue1_c(y-x,5) = data.num_cues - x;
        end
    end
end
time.cue1_c(:,7) = 2;
% under timing save the original jitter so it can be checked
timing.origcue1_c = time.cue1_c;

% create times for targets
clear n
for n = 1:data.numtri_c;
    time.targ_c(n,:) = (time.jump_targc .* n) + data.targ_start;
end
% if multiple TRs being jittered over ensure sampling is good by setting
% the second TR's jitter to sit exactly between the first TR's jitter
if data.num_tr.targ > 1;
    clear a
    a = ((time.targ_c(1,1) - data.targ_start) ./ 2) - (time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1),1) - (data.tr + data.targ_start));
    if a < (time.targ_c(1,1) - data.targ_start) ./ 2;
        time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) = time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) + a;
    else
        time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) = time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) - a;
    end
end
timing.origtarg_c = time.targ_c;

% create times for feedback
clear n
for n = 1:data.numtri_c;
    time.feed_c(n,:) = (time.jump_feedc .* n) + data.feed_start;
end
% if multiple TRs being jittered over ensure sampling is good
if data.num_tr.feed > 1;
    clear a
    a = ((time.feed_c(1,1) - data.feed_start) ./ 2) - (time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1),1) - (data.tr + data.feed_start));
    if a < (time.feed_c(1,1) - data.feed_start) ./ 2;
        time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) = time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) + a;
    else
        time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) = time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) - a;
    end
end
timing.origfeed_c = time.feed_c;


% randomise
time.cue1_c(:,1) = rand(1,data.numtri_c);
time.cue1_c = sortrows(time.cue1_c,1);
time.targ_c(:,2) = rand(1,data.numtri_c);
time.targ_c = sortrows(time.targ_c,2);
time.feed_c(:,2) = rand(1,data.numtri_c);
time.feed_c = sortrows(time.feed_c,2);
clear RHO1
clear RHO2
clear RHO3
[RHO1,PVAL1] = corr(time.cue1_c(:,2),time.targ_c(:,1));
[RHO2,PVAL2] = corr(time.cue1_c(:,2),time.feed_c(:,1));
[RHO3,PVAL3] = corr(time.targ_c(:,1),time.feed_c(:,1));
time.r.c = max([abs(RHO1) abs(RHO2) abs(RHO3)]);

% loops through until the cue and target onset times are maximally
% uncorrelated
while time.r.c > data.r_thresh;
    % randomise
    time.cue1_c(:,1) = rand(1,data.numtri_c);
    time.cue1_c = sortrows(time.cue1_c,1);
    time.targ_c(:,2) = rand(1,data.numtri_c);
    time.targ_c = sortrows(time.targ_c,2);
    time.feed_c(:,2) = rand(1,data.numtri_c);
    time.feed_c = sortrows(time.feed_c,2);
    clear RHO1
    clear RHO2
    clear RHO3
    [RHO1,PVAL1] = corr(time.cue1_c(:,2),time.targ_c(:,1));
    [RHO2,PVAL2] = corr(time.cue1_c(:,2),time.feed_c(:,1));
    [RHO3,PVAL3] = corr(time.targ_c(:,1),time.feed_c(:,1));
    time.r.c = max([abs(RHO1) abs(RHO2) abs(RHO3)]);

end

% add target times to the main list
time.c = time.cue1_c;
time.c(:,1) = 0;
time.c(:,3) = time.targ_c(:,1);
time.c(:,4) = time.feed_c(:,1);

% create zero columns for later stacking
time.c(:,8:9) = 0;

"control correlations fixed"




% check the jitter
clear n
for n = 1:length(timing.origcue1_x(:,1));
    timing.jitter_cue1x(n,1) = 1;
    if timing.origcue1_x(n,2) < (data.tr + data.cue_start);
        timing.jitter_cue1x(n,2) = timing.origcue1_x(n,2);
    else
        timing.jitter_cue1x(n,2) = timing.origcue1_x(n,2) - data.tr;
    end
end
figure(1);
subplot(3,2,1);
scatter(timing.jitter_cue1x(:,2),timing.jitter_cue1x(:,1),'filled');
title('cue1x');

clear n
for n = 1:length(timing.origcue1_c(:,2));
    timing.jitter_cue1c(n,1) = 1;
    if timing.origcue1_c(n,2) < (data.tr + data.cue_start);
        timing.jitter_cue1c(n,2) = timing.origcue1_c(n,2);
    else
        timing.jitter_cue1c(n,2) = timing.origcue1_c(n,2) - data.tr;
    end
end
figure(1);
subplot(3,2,2);
scatter(timing.jitter_cue1c(:,2),timing.jitter_cue1c(:,1),'filled');
title('cue1c');

% check the jitter - targets
clear n
for n = 1:length(timing.origtarg_x(:,1));
    timing.jitter_targx(n,1) = 1;
    if timing.origtarg_x(n,1) < (data.tr + data.targ_start);
        timing.jitter_targx(n,2) = timing.origtarg_x(n,1);
    else
        timing.jitter_targx(n,2) = timing.origtarg_x(n,1) - data.tr;
    end
end
figure(1);
subplot(3,2,3);
scatter(timing.jitter_targx(:,2),timing.jitter_targx(:,1),'filled');
title('targx');

clear n
for n = 1:length(timing.origtarg_c(:,1));
    timing.jitter_targc(n,1) = 1;
    if timing.origtarg_c(n,1) < (data.tr + data.targ_start);
        timing.jitter_targc(n,2) = timing.origtarg_c(n,1);
    else
        timing.jitter_targc(n,2) = timing.origtarg_c(n,1) - data.tr;
    end
end
figure(1);
subplot(3,2,4);
scatter(timing.jitter_targc(:,2),timing.jitter_targc(:,1),'filled');
title('targc');

% check the jitter - feedback
clear n
for n = 1:length(timing.origfeed_x(:,1));
    timing.jitter_feedx(n,1) = 1;
    if timing.origfeed_x(n,1) < (data.tr + data.feed_start);
        timing.jitter_feedx(n,2) = timing.origfeed_x(n,1);
    else
        timing.jitter_feedx(n,2) = timing.origfeed_x(n,1) - data.tr;
    end
end
figure(1);
subplot(3,2,5);
scatter(timing.jitter_feedx(:,2),timing.jitter_feedx(:,1),'filled');
title('feedx');

clear n
for n = 1:length(timing.origfeed_c(:,1));
    timing.jitter_feedc(n,1) = 1;
    if timing.origfeed_c(n,1) < (data.tr + data.feed_start);
        timing.jitter_feedc(n,2) = timing.origfeed_c(n,1);
    else
        timing.jitter_feedc(n,2) = timing.origfeed_c(n,1) - data.tr;
    end
end
figure(1);
subplot(3,2,6);
scatter(timing.jitter_feedc(:,2),timing.jitter_feedc(:,1),'filled');
title('feedc');


% now I compile all the trials into their respective blocks
clear n

% first separate into each cue type for exp and control
for n = 1:data.num_cues;
    % find each set of experimental cue types sequentially
    clear my_field
    my_field = strcat('x_',num2str(n));
    block.(my_field) = time.x(find(time.x(:,5) == n),:);
    % do the same for the control cue types
    clear my_field
    my_field = strcat('c_',num2str(n));
    block.(my_field) = time.c(find(time.c(:,5) == n),:);
end

% then spread these equally over blocks
clear numx
clear numc
numx = (data.numtri_x ./ data.tot_num_blocks) ./ data.num_cues;
numc = (data.numtri_c ./ data.tot_num_blocks) ./ data.num_cues;
clear n
for n = 1:data.tot_num_blocks;
    clear a
    a = strcat('block_',num2str(n));
    clear m
    for m = 1:data.num_cues;
        clear b
        b = strcat('x_',num2str(m));
        block.(a)(((m - 1) .* numx) + 1:m .* numx,:) = block.(b)(((n - 1) .* numx) + 1: n .* numx,:);
    end
    clear m
    for m = 1:data.num_cues;
        % now add in the control trials
        clear b
        b = strcat('c_',num2str(m));
        block.(a)(length(block.(a)(:,1)) + 1:length(block.(a)(:,1)) + numc,:) = block.(b)(((n - 1) .* numc) + 1: n .* numc,:);
    end
    % set the block number in column 8
    block.(a)(:,8) = n;
end

clear n
for n = 1:data.tot_num_blocks;
    clear a
    a = strcat('block_',num2str(n));
    for m = 1:2;
        clear b
        b = strcat('block_',num2str(n),'_con_',num2str(m));
        block.(b) = block.(a)(find(block.(a)(:,7) == m),:);
    end
end

% randomise the blocks but offsetting slightly so control trials are
% typically later
clear n
for n = 1:data.tot_num_blocks;
    clear a
    a = strcat('block_',num2str(n));
    clear b
    b = strcat('rand_',num2str(n));

    % randomise with offsets
    block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
    block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));
    block.(b) = sortrows(block.(a),1);
    % check for repetitions of 3 in a row (matched cue and control)
    clear t
    t = 0;
    clear m
    for m = 3:length(block.(b)(:,1));
        if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
           block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
           t = 1;
        end
    end
    % if repeated re-randomise
    while t == 1;
        block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
        block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));    
        block.(b) = sortrows(block.(a),1);
        % check for repetitions
        clear t
        t = 0;
        clear m
        for m = 3:length(block.(b)(:,1));
            if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
               block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
               t = 1;
            end
        end
    end
end


% now concatenate all the blocks into a single run
clear n
total.whole_run = block.rand_1;
for n = 2:data.tot_num_blocks
    clear a
    a = strcat('rand_',num2str(n));
    total.whole_run(length(total.whole_run(:,1)) + 1:length(total.whole_run(:,1)) +...
    ((data.tot_num_trials ./ data.tot_num_blocks)),:) = block.(a);
end



% then make this run continuous and in seconds
% first set the respective trial length
clear n
for n = 1:length(total.whole_run(:,1));
    total.whole_run(n,9) = data.trilen .* 1000;
end
% then make these cumulative
clear n
for n = 2:length(total.whole_run(:,1));
    total.whole_run(n,9) = total.whole_run(n,9) + total.whole_run(n - 1,9);
end

% now make the trial times cumulative
clear n
total.run2(1,:) = total.whole_run(1,:);
for n = 2:length(total.whole_run(:,1));
    total.run2(n,:) = total.whole_run(n,:);
    total.run2(n,2:4) = total.run2(n,2:4) + total.run2(n-1,9);
end


% convert to seconds
total.run2(:,2:4) = total.run2(:,2:4) ./ 1000;


% now check to ensure there are always more or an equal number of experimental
% trials to control trials, to make the dynamic control condition work.
clear n
for n = 1:data.num_cues;
    clear a
    a = num2str(n);
    dynamic.(strcat('cue_',a)) = total.run2(find(total.run2(:,5) == n),:);
end

clear aa
aa = 0;
clear n
clear m
for m = 1:data.num_cues;
    mst = num2str(m);
    clear count
    count = 0;
    for n = 1:length(dynamic.(strcat('cue_',mst))(:,1));
        if dynamic.(strcat('cue_',mst))(n,7) == 1;
            count = count + 1;
        elseif dynamic.(strcat('cue_',mst))(n,7) == 2;
            count = count - 1;
        end
        if count < 0;
            aa = 1;
        end
    end
end

% catch any incidence of the number of controls exceeding the number of
% experimental, and re randomise until fixed
while aa ~= 0;
    % randomise the blocks but offsetting slightly so control trials are
    % typically later
    clear n
    for n = 1:data.tot_num_blocks;
        clear a
        a = strcat('block_',num2str(n));
        clear b
        b = strcat('rand_',num2str(n));
        block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
        block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));    
        block.(b) = sortrows(block.(a),1);
        % check for repetitions of 3 in a row (matched cue and control)
        clear t
        t = 0;
        clear m
        for m = 3:length(block.(b)(:,1));
            if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
               block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
               t = 1;
            end
        end
        % if repeated re-randomise
        while t == 1;
            block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
            block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));    
            block.(b) = sortrows(block.(a),1);
            % check for repetitions
            clear t
            t = 0;
            clear m
            for m = 3:length(block.(b)(:,1));
                if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
                   block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
                   t = 1;
                end
            end
        end
    end
    
    
    % now concatenate all the blocks into a single run
    clear n
    total.whole_run = block.rand_1;
    for n = 2:data.tot_num_blocks
        clear a
        a = strcat('rand_',num2str(n));
        total.whole_run(length(total.whole_run(:,1)) + 1:length(total.whole_run(:,1)) +...
        ((data.tot_num_trials ./ data.tot_num_blocks)),:) = block.(a);
    end
    
    
    
    % then make this run continuous and in seconds
    % first set the respective trial length
    clear n
    for n = 1:length(total.whole_run(:,1));
        total.whole_run(n,9) = data.trilen .* 1000;
    end
    % then make these cumulative
    clear n
    for n = 2:length(total.whole_run(:,1));
        total.whole_run(n,9) = total.whole_run(n,9) + total.whole_run(n - 1,9);
    end
    
    % now make the trial times cumulative
    clear n
    total.run2(1,:) = total.whole_run(1,:);
    for n = 2:length(total.whole_run(:,1));
        total.run2(n,:) = total.whole_run(n,:);
        total.run2(n,2:4) = total.run2(n,2:4) + total.run2(n-1,9);
    end
    
    
    % convert to seconds
    total.run2(:,2:4) = total.run2(:,2:4) ./ 1000;
    
    
    % now check to ensure there are always more or an equal number of experimental
    % trials to control trials, to make the dynamic control condition work.
    clear n
    for n = 1:data.num_cues;
        clear a
        a = num2str(n);
        dynamic.(strcat('cue_',a)) = total.run2(find(total.run2(:,5) == n),:);
    end
    
    clear aa
    aa = 0;
    clear n
    clear m
    for m = 1:data.num_cues;
        mst = num2str(m);
        clear count
        count = 0;
        for n = 1:length(dynamic.(strcat('cue_',mst))(:,1));
            if dynamic.(strcat('cue_',mst))(n,7) == 1;
                count = count + 1;
            elseif dynamic.(strcat('cue_',mst))(n,7) == 2;
                count = count - 1;
            end
            if count < 0;
                aa = 1;
            end
        end
    end
end

"dynamic control condition ready"

% need to consider conditions of interest
clear n
for n = 1:data.num_cues;
    clear a
    a = strcat('cue_',num2str(n));
    cond.x.(a) = dynamic.(a)(find(dynamic.(a)(:,7) == 1),:);
    cond.c.(a) = dynamic.(a)(find(dynamic.(a)(:,7) == 2),:);
    % add in an estimate of the performance within the 10th column, roughly speaking (0 = inc, 1 =
    % cor). Firstly works out the performance odds if memory is perfect
    % (but never dipping below 90% performance as people are never
    % perfect). It then introduces a measure of error proportional to the
    % odds.
    clear m
    for m = 1:length(cond.x.(a)(:,1));
        clear b
        b = rand(1);
        % look at the first trial, as this is pure chance
        if m == 1;
            if b > (100 - (100 ./ (data.num_targets - (m - 1)))) ./ 100;
                cond.x.(a)(m,10) = 1;
                cond.c.(a)(m,10) = 1;
            else
                cond.x.(a)(m,10) = 0;
                cond.c.(a)(m,10) = 0;
            end
        % then look at all subsequent trials and make the probability based
        % upon past performance
        else
            % looks at instances of there being at least 2 options left to
            % guess between, and not having got the correct answer yet
            if m < data.num_targets & sum(cond.x.(a)(1:m,10)) < 1;
                % I work out the odds of getting it right based upon
                % perfect recall, then add 2.5 multiplied by the trial
                % number as the degree of error (which I set to increase as
                % the trial number increases in order to account for having
                % more incorrect optiosn to recall. E.g. it is easy to
                % remember not the far right target, but harder to recall
                % not the far right and middle. Also over trials the number
                % of other bits of information in other trials increases,
                % altering the difficulty).
                if b > ((100 - (100 ./ (data.num_targets - (m - 1)))) + (2.5 .* m)) ./ 100;
                    cond.x.(a)(m,10) = 1;
                    cond.c.(a)(m,10) = 1;
                else
                    cond.x.(a)(m,10) = 0;
                    cond.c.(a)(m,10) = 0;
                end
                % specifies what happens when there is just one option left
                % statistically (assumes of course that we had no error
                % based repetition) either through odds, or through having
                % found the correct answer once already.
            else
                if b > (data.performance - (m ./ 100));
                    cond.x.(a)(m,10) = 1;
                    cond.c.(a)(m,10) = 1;
                else
                    cond.x.(a)(m,10) = 0;
                    cond.c.(a)(m,10) = 0;
                end
            end
        end
    end



    % now classify into the relevant trial types
    % 1 = the error in error-correct pairs
    % 2 = the correct in error-correct pairs
    % 3 = the initial correct in correct-correct pairs
    % 4 = the second correct in correct-correct pairs
    % 5 = all remaining errors
    % 6 = all remaining correct
    % then this repeats through the control trials
    clear m
    cond.x.(a)(:,11) = 999;
    for m = 2:length(cond.x.(a)(:,1));
        % isolate the first loop as we needn't worry about m-2 here
        if m == 2;
            if cond.x.(a)(m-1,10) == 0 & cond.x.(a)(m,10) == 1;
                if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                    % error before correct
                    cond.x.(a)(m-1,11) = 1;
                    % correct after error
                    cond.x.(a)(m,11) = 2;
                end
            elseif cond.x.(a)(m-1,10) == 1 & cond.x.(a)(m,10) == 1;
                if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                    % correct before correct
                    cond.x.(a)(m-1,11) = 3;
                    % correct after correct
                    cond.x.(a)(m,11) = 4;
                end
            end
            
            % look at all loops from the 2nd onwards where m-3 matters (as
            % we cannot use 0-1 trials which are 0-0-1
        else
            if cond.x.(a)(m-2,10) == 1 & cond.x.(a)(m-1,10) == 0 & cond.x.(a)(m,10) == 1;
                if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                    % error before correct
                    cond.x.(a)(m-1,11) = 1;
                    % correct after error
                    cond.x.(a)(m,11) = 2;
                end
                % and we cannot use 1-1 trials which are 0-1-1 due to the
                % removal of the 0-0-1 trials (without this removal 0-1-1
                % would be impossible as it would have been a 0-1 trial)
            elseif cond.x.(a)(m-2,10) == 1 & cond.x.(a)(m-1,10) == 1 & cond.x.(a)(m,10) == 1;
                if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                    % correct before correct
                    cond.x.(a)(m-1,11) = 3;
                    % correct after correct
                    cond.x.(a)(m,11) = 4;
                end
            end
        end
    end
    cond.x.(a)(find(cond.x.(a)(:,11) == 999 & cond.x.(a)(:,10) == 0),11) = 5;
    cond.x.(a)(find(cond.x.(a)(:,11) == 999 & cond.x.(a)(:,10) == 1),11) = 6;
    cond.c.(a)(:,11) = cond.x.(a)(:,11) + 6;
end

% loop through each cue in each condition:
% IN THE 11th COLUMN
% 1 = x err-cor 1st
% 2 = x err-cor 2nd
% 3 = x cor-cor 1st
% 4 = x cor-cor 2nd
% 5 = x remaining err
% 6 = x remaining cor
% 7 = c err-cor 1st
% 8 = c err-cor 2nd
% 9 = c cor-cor 1st
% 10 = c cor-cor 2nd
% 11 = c remaining err
% 12 = c remaining cor

total.run3 = [cond.x.cue_1; cond.c.cue_1];
for n = 2:data.num_cues;
    total.run3 = [total.run3; eval(strcat('cond.x.cue_',num2str(n))); eval(strcat('cond.c.cue_',num2str(n)))]
end
% next organise by 2nd column
total.run3 = sortrows(total.run3,2);

% find the number of each trial type
totals(1) = length(find(total.run3(:,11) == 1));
totals(2) = length(find(total.run3(:,11) == 2));
totals(3) = length(find(total.run3(:,11) == 3));
totals(4) = length(find(total.run3(:,11) == 4));
totals(5) = length(find(total.run3(:,11) == 5));
totals(6) = length(find(total.run3(:,11) == 6));


% load the HRFc function
data.hrfc = importdata('HRFc.mat')';
% check how many cells per second
data.sec = length(data.hrfc) ./ 32.0125;
% calculate the length of the design matrix in cells
clear x
x = max(max(total.run2(:,4)));
clear y
y = ceil(x .* data.sec) + length(data.hrfc);

% create the faux design matrix
cond.design(1:y,1:data.num_regressors) = 0;

% create the regressors (1-12 refers to the 12 possible cue related
% pairings)
clear n
for n = 1:12;
    clear a
    a = strcat('con_',num2str(n));
    cond.(a) = total.run3(find(total.run3(:,11) == n),2);
    clear m
    for m = 1:length(cond.(a));
        clear x
        x = ceil(cond.(a)(m) .* data.sec);
        cond.design(x:x+259,n) = cond.design(x:x+259,n) + data.hrfc;
    end
end

% do the rest
clear m
for m = 1:length(total.run3(:,1));
    % if experimental
    if total.run3(m,7) == 1 & total.run3(m,5) < 4;
        % target
        clear x
        x = ceil(total.run3(m,3) .* data.sec);
        cond.design(x:x+259,13) = cond.design(x:x+259,13) + data.hrfc;
    elseif total.run3(m,7) == 1 & total.run3(m,5) > 3 & total.run3(m,5) < 7;
        % target
        clear x
        x = ceil(total.run3(m,3) .* data.sec);
        cond.design(x:x+259,14) = cond.design(x:x+259,14) + data.hrfc;
    elseif total.run3(m,7) == 1 & total.run3(m,5) > 6;
        % target
        clear x
        x = ceil(total.run3(m,3) .* data.sec);
        cond.design(x:x+259,15) = cond.design(x:x+259,15) + data.hrfc;
    % control
    elseif total.run3(m,7) == 2 & total.run3(m,5) < 4;
        % target
        clear x
        x = ceil(total.run3(m,3) .* data.sec);
        cond.design(x:x+259,16) = cond.design(x:x+259,16) + data.hrfc;
    elseif total.run3(m,7) == 2 & total.run3(m,5) > 3 & total.run3(m,5) < 7;
        % target
        clear x
        x = ceil(total.run3(m,3) .* data.sec);
        cond.design(x:x+259,17) = cond.design(x:x+259,17) + data.hrfc;
    elseif total.run3(m,7) == 2 & total.run3(m,5) > 6;
        % target
        clear x
        x = ceil(total.run3(m,3) .* data.sec);
        cond.design(x:x+259,18) = cond.design(x:x+259,18) + data.hrfc;
    end
    % work through the feedback
    % correct exp first
    if total.run3(m,7) == 1 & total.run3(m,10) == 1;
        clear x
        x = ceil(total.run3(m,4) .* data.sec);
        cond.design(x:x+259,19) = cond.design(x:x+259,19) + data.hrfc;
    % then incorrect exp
    elseif total.run3(m,7) == 1 & total.run3(m,10) == 0;
        clear x
        x = ceil(total.run3(m,4) .* data.sec);
        cond.design(x:x+259,20) = cond.design(x:x+259,20) + data.hrfc;
    % then correct con
    elseif total.run3(m,7) == 2 & total.run3(m,10) == 1;
        clear x
        x = ceil(total.run3(m,4) .* data.sec);
        cond.design(x:x+259,21) = cond.design(x:x+259,21) + data.hrfc;
    % then incorrect con
    elseif total.run3(m,7) == 2 & total.run3(m,10) == 0;
        clear x
        x = ceil(total.run3(m,4) .* data.sec);
        cond.design(x:x+259,22) = cond.design(x:x+259,22) + data.hrfc;
    end
end

% EXPERIMENTAL
% 1 = the error in error-correct pairs
% 2 = the correct in error-correct pairs
% 3 = the initial correct in correct-correct pairs
% 4 = the second correct in correct-correct pairs
% 5 = all remaining errors
% 6 = all remaining correct
% CONTROL
% 7 = the error in error-correct pairs
% 8 = the correct in error-correct pairs
% 9 = the initial correct in correct-correct pairs
% 10 = the second correct in correct-correct pairs
% 11 = all remaining errors
% 12 = all remaining correct
% REMAINING
% 13 = X targ 1:3
% 14 = X targ 4:6
% 15 = X targ 7:10
% 16 = C targ 1:3
% 17 = C targ 4:6
% 18 = C targ 7:10
% 19 = X feed cor
% 20 = X feed incor
% 21 = C feed cor
% 22 = C feed incor

% create a correlation matrix
cond.correlate = corrcoef(cond.design);

% remove 1s
clear n
for n = 1:length(cond.correlate(:,1));
    cond.correlate(n,n) = 0;
end

clear max_j
cond.max_correlate = max(max(abs(cond.correlate(1:12,[1:4,7:10]))));
total.duration = max(max(total.run2(:,4))) ./ 60;
cond.max_correlate_all = max(max(abs(cond.correlate(:,[1:4,7:10]))))

save block block
save cond cond
save data data
save time time
save timing timing
save total total
save totals totals
save dynamic dynamic
save counter counter








while cond.max_correlate_all > data.rep_thresh;
    clear all
    load('data.mat');

    %%%% EXPERIMENTAL %%%%

    % prep the jitter. Each is jittered over 1750ms, but this can vary
    clear n
    time.jump_cuex = ((data.tr .* data.num_tr.cue) - data.jitter.cue - data.del.cue) ./ data.numtri_x;
    time.jump_targx = ((data.tr .* data.num_tr.targ) - data.jitter.targ - data.del.targ) ./ data.numtri_x;
    time.jump_feedx = ((data.tr .* data.num_tr.feed) - data.jitter.feed - data.del.feed) ./ data.numtri_x;
    
    % loop through and create timings
    for n = 1:data.numtri_x;
        time.cue1_x(n,2) = (time.jump_cuex .* n) + data.cue_start;
    end
    % if multiple TRs being jittered over ensure sampling is good
    if data.num_tr.cue > 1;
        clear a
        a = (time.cue1_x(1,2) ./ 2) - (time.cue1_x(find(time.cue1_x(:,2) > data.tr,1),2) - data.tr);
        if a < time.cue1_x(1,2) ./ 2;
            time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) = time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) + a;
        else
            time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) = time.cue1_x(find(time.cue1_x(:,2) > data.tr,1):length(time.cue1_x(:,1)),2) - a;
        end
    end
    % now add the attributes:
    % column 2 = cue timing
    % column 3 = target timing
    % column 5 = cue type
    % column 7 = experimental condition (1 = x, 2 = c)
    time.cue1_x(:,5) = 1;
    clear n
    for n = 1:data.numtri_x ./ data.num_cues;
        clear y
        y = n .* data.num_cues;
        time.cue1_x(y,5) = data.num_cues;
        if data.num_cues > 2;
            clear x
            for x = 1:data.num_cues - 2;
                time.cue1_x(y-x,5) = data.num_cues - x;
            end
        end
    end
    time.cue1_x(:,7) = 1;
    % under timing save the original jitter so it can be checked
    timing.origcue1_x = time.cue1_x;
    
    % create times for targets
    clear n
    for n = 1:data.numtri_x;
        time.targ_x(n,:) = (time.jump_targx .* n) + data.targ_start;
    end
    % if multiple TRs being jittered over ensure sampling is good
    if data.num_tr.targ > 1;
        clear a
        a = ((time.targ_x(1,1) - data.targ_start) ./ 2) - (time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1),1) - (data.tr + data.targ_start));
        if a < (time.targ_x(1,1) - data.targ_start) ./ 2;
            time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) = time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) + a;
        else
            time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) = time.targ_x(find(time.targ_x(:,1) > (data.tr + data.targ_start),1):length(time.targ_x(:,1)),1) - a;
        end
    end
    timing.origtarg_x = time.targ_x;
    
    % create times for feedback
    clear n
    for n = 1:data.numtri_x;
        time.feed_x(n,:) = (time.jump_feedx .* n) + data.feed_start;
    end
    % if multiple TRs being jittered over ensure sampling is good
    if data.num_tr.feed > 1;
        clear a
        a = ((time.feed_x(1,1) - data.feed_start) ./ 2) - (time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1),1) - (data.tr + data.feed_start));
        if a < (time.feed_x(1,1) - data.feed_start) ./ 2;
            time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) = time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) + a;
        else
            time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) = time.feed_x(find(time.feed_x(:,1) > (data.tr + data.feed_start),1):length(time.feed_x(:,1)),1) - a;
        end
    end
    timing.origfeed_x = time.feed_x;
    
    
    % randomise
    time.cue1_x(:,1) = rand(1,data.numtri_x);
    time.cue1_x = sortrows(time.cue1_x,1);
    time.targ_x(:,2) = rand(1,data.numtri_x);
    time.targ_x = sortrows(time.targ_x,2);
    time.feed_x(:,2) = rand(1,data.numtri_x);
    time.feed_x = sortrows(time.feed_x,2);
    clear RHO1
    clear RHO2
    clear RHO3
    [RHO1,PVAL1] = corr(time.cue1_x(:,2),time.targ_x(:,1));
    [RHO2,PVAL2] = corr(time.cue1_x(:,2),time.feed_x(:,1));
    [RHO3,PVAL3] = corr(time.targ_x(:,1),time.feed_x(:,1));
    time.r.x = max([abs(RHO1) abs(RHO2) abs(RHO3)]);
    
    % loops through until the cue and target onset times are maximally
    % uncorrelated
    while time.r.x > data.r_thresh;
        % randomise
        time.cue1_x(:,1) = rand(1,data.numtri_x);
        time.cue1_x = sortrows(time.cue1_x,1);
        time.targ_x(:,2) = rand(1,data.numtri_x);
        time.targ_x = sortrows(time.targ_x,2);
        time.feed_x(:,2) = rand(1,data.numtri_x);
        time.feed_x = sortrows(time.feed_x,2);
        clear RHO1
        clear RHO2
        clear RHO3
        [RHO1,PVAL1] = corr(time.cue1_x(:,2),time.targ_x(:,1));
        [RHO2,PVAL2] = corr(time.cue1_x(:,2),time.feed_x(:,1));
        [RHO3,PVAL3] = corr(time.targ_x(:,1),time.feed_x(:,1));
        time.r.x = max([abs(RHO1) abs(RHO2) abs(RHO3)]);
    
    end
    
    % add target times to the main list
    time.x = time.cue1_x;
    time.x(:,1) = 0;
    time.x(:,3) = time.targ_x(:,1);
    time.x(:,4) = time.feed_x(:,1);
    
    % create zero columns for later stacking
    time.x(:,8:9) = 0;
    
    "experimental correlations fixed"
    
    
    
    
    
    %%%% CONTROL %%%%
    
    % prep the jitter. Each is jittered over 1750ms, but this can vary
    clear n
    time.jump_cuec = ((data.tr .* data.num_tr.cue) - data.jitter.cue - data.del.cue) ./ data.numtri_c;
    time.jump_targc = ((data.tr .* data.num_tr.targ) - data.jitter.targ - data.del.targ) ./ data.numtri_c;
    time.jump_feedc = ((data.tr .* data.num_tr.feed) - data.jitter.feed - data.del.feed) ./ data.numtri_c;
    
    % loop through and create timings
    for n = 1:data.numtri_c;
        time.cue1_c(n,2) = (time.jump_cuec .* n) + data.cue_start;
    end
    % if multiple TRs being jittered over ensure sampling is good
    if data.num_tr.cue > 1;
        clear a
        a = (time.cue1_c(1,2) ./ 2) - (time.cue1_c(find(time.cue1_c(:,2) > data.tr,1),2) - data.tr);
        if a < time.cue1_c(1,2) ./ 2;
            time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) = time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) + a;
        else
            time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) = time.cue1_c(find(time.cue1_c(:,2) > data.tr,1):length(time.cue1_c(:,1)),2) - a;
        end
    end
    % now add the attributes:
    % column 2 = cue timing
    % column 3 = target timing
    % column 5 = cue type
    % column 7 = experimental condition (1 = x, 2 = c)
    time.cue1_c(:,5) = 1;
    clear n
    for n = 1:data.numtri_c ./ data.num_cues;
        clear y
        y = n .* data.num_cues;
        time.cue1_c(y,5) = data.num_cues;
        if data.num_cues > 2;
            clear x
            for x = 1:data.num_cues - 2;
                time.cue1_c(y-x,5) = data.num_cues - x;
            end
        end
    end
    time.cue1_c(:,7) = 2;
    % under timing save the original jitter so it can be checked
    timing.origcue1_c = time.cue1_c;
    
    % create times for targets
    clear n
    for n = 1:data.numtri_c;
        time.targ_c(n,:) = (time.jump_targc .* n) + data.targ_start;
    end
    % if multiple TRs being jittered over ensure sampling is good by setting
    % the second TR's jitter to sit exactly between the first TR's jitter
    if data.num_tr.targ > 1;
        clear a
        a = ((time.targ_c(1,1) - data.targ_start) ./ 2) - (time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1),1) - (data.tr + data.targ_start));
        if a < (time.targ_c(1,1) - data.targ_start) ./ 2;
            time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) = time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) + a;
        else
            time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) = time.targ_c(find(time.targ_c(:,1) > (data.tr + data.targ_start),1):length(time.targ_c(:,1)),1) - a;
        end
    end
    timing.origtarg_c = time.targ_c;
    
    % create times for feedback
    clear n
    for n = 1:data.numtri_c;
        time.feed_c(n,:) = (time.jump_feedc .* n) + data.feed_start;
    end
    % if multiple TRs being jittered over ensure sampling is good
    if data.num_tr.feed > 1;
        clear a
        a = ((time.feed_c(1,1) - data.feed_start) ./ 2) - (time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1),1) - (data.tr + data.feed_start));
        if a < (time.feed_c(1,1) - data.feed_start) ./ 2;
            time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) = time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) + a;
        else
            time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) = time.feed_c(find(time.feed_c(:,1) > (data.tr + data.feed_start),1):length(time.feed_c(:,1)),1) - a;
        end
    end
    timing.origfeed_c = time.feed_c;
    
    
    % randomise
    time.cue1_c(:,1) = rand(1,data.numtri_c);
    time.cue1_c = sortrows(time.cue1_c,1);
    time.targ_c(:,2) = rand(1,data.numtri_c);
    time.targ_c = sortrows(time.targ_c,2);
    time.feed_c(:,2) = rand(1,data.numtri_c);
    time.feed_c = sortrows(time.feed_c,2);
    clear RHO1
    clear RHO2
    clear RHO3
    [RHO1,PVAL1] = corr(time.cue1_c(:,2),time.targ_c(:,1));
    [RHO2,PVAL2] = corr(time.cue1_c(:,2),time.feed_c(:,1));
    [RHO3,PVAL3] = corr(time.targ_c(:,1),time.feed_c(:,1));
    time.r.c = max([abs(RHO1) abs(RHO2) abs(RHO3)]);
    
    % loops through until the cue and target onset times are maximally
    % uncorrelated
    while time.r.c > data.r_thresh;
        % randomise
        time.cue1_c(:,1) = rand(1,data.numtri_c);
        time.cue1_c = sortrows(time.cue1_c,1);
        time.targ_c(:,2) = rand(1,data.numtri_c);
        time.targ_c = sortrows(time.targ_c,2);
        time.feed_c(:,2) = rand(1,data.numtri_c);
        time.feed_c = sortrows(time.feed_c,2);
        clear RHO1
        clear RHO2
        clear RHO3
        [RHO1,PVAL1] = corr(time.cue1_c(:,2),time.targ_c(:,1));
        [RHO2,PVAL2] = corr(time.cue1_c(:,2),time.feed_c(:,1));
        [RHO3,PVAL3] = corr(time.targ_c(:,1),time.feed_c(:,1));
        time.r.c = max([abs(RHO1) abs(RHO2) abs(RHO3)]);
    
    end
    
    % add target times to the main list
    time.c = time.cue1_c;
    time.c(:,1) = 0;
    time.c(:,3) = time.targ_c(:,1);
    time.c(:,4) = time.feed_c(:,1);
    
    % create zero columns for later stacking
    time.c(:,8:9) = 0;
    
    "control correlations fixed"
    
    
    
    
    % check the jitter
    clear n
    for n = 1:length(timing.origcue1_x(:,1));
        timing.jitter_cue1x(n,1) = 1;
        if timing.origcue1_x(n,2) < (data.tr + data.cue_start);
            timing.jitter_cue1x(n,2) = timing.origcue1_x(n,2);
        else
            timing.jitter_cue1x(n,2) = timing.origcue1_x(n,2) - data.tr;
        end
    end
    figure(1);
    subplot(3,2,1);
    scatter(timing.jitter_cue1x(:,2),timing.jitter_cue1x(:,1),'filled');
    title('cue1x');
    
    clear n
    for n = 1:length(timing.origcue1_c(:,2));
        timing.jitter_cue1c(n,1) = 1;
        if timing.origcue1_c(n,2) < (data.tr + data.cue_start);
            timing.jitter_cue1c(n,2) = timing.origcue1_c(n,2);
        else
            timing.jitter_cue1c(n,2) = timing.origcue1_c(n,2) - data.tr;
        end
    end
    figure(1);
    subplot(3,2,2);
    scatter(timing.jitter_cue1c(:,2),timing.jitter_cue1c(:,1),'filled');
    title('cue1c');
    
    % check the jitter - targets
    clear n
    for n = 1:length(timing.origtarg_x(:,1));
        timing.jitter_targx(n,1) = 1;
        if timing.origtarg_x(n,1) < (data.tr + data.targ_start);
            timing.jitter_targx(n,2) = timing.origtarg_x(n,1);
        else
            timing.jitter_targx(n,2) = timing.origtarg_x(n,1) - data.tr;
        end
    end
    figure(1);
    subplot(3,2,3);
    scatter(timing.jitter_targx(:,2),timing.jitter_targx(:,1),'filled');
    title('targx');
    
    clear n
    for n = 1:length(timing.origtarg_c(:,1));
        timing.jitter_targc(n,1) = 1;
        if timing.origtarg_c(n,1) < (data.tr + data.targ_start);
            timing.jitter_targc(n,2) = timing.origtarg_c(n,1);
        else
            timing.jitter_targc(n,2) = timing.origtarg_c(n,1) - data.tr;
        end
    end
    figure(1);
    subplot(3,2,4);
    scatter(timing.jitter_targc(:,2),timing.jitter_targc(:,1),'filled');
    title('targc');
    
    % check the jitter - feedback
    clear n
    for n = 1:length(timing.origfeed_x(:,1));
        timing.jitter_feedx(n,1) = 1;
        if timing.origfeed_x(n,1) < (data.tr + data.feed_start);
            timing.jitter_feedx(n,2) = timing.origfeed_x(n,1);
        else
            timing.jitter_feedx(n,2) = timing.origfeed_x(n,1) - data.tr;
        end
    end
    figure(1);
    subplot(3,2,5);
    scatter(timing.jitter_feedx(:,2),timing.jitter_feedx(:,1),'filled');
    title('feedx');
    
    clear n
    for n = 1:length(timing.origfeed_c(:,1));
        timing.jitter_feedc(n,1) = 1;
        if timing.origfeed_c(n,1) < (data.tr + data.feed_start);
            timing.jitter_feedc(n,2) = timing.origfeed_c(n,1);
        else
            timing.jitter_feedc(n,2) = timing.origfeed_c(n,1) - data.tr;
        end
    end
    figure(1);
    subplot(3,2,6);
    scatter(timing.jitter_feedc(:,2),timing.jitter_feedc(:,1),'filled');
    title('feedc');
    
    
    % now I compile all the trials into their respective blocks
    clear n
    
    % first separate into each cue type for exp and control
    for n = 1:data.num_cues;
        % find each set of experimental cue types sequentially
        clear my_field
        my_field = strcat('x_',num2str(n));
        block.(my_field) = time.x(find(time.x(:,5) == n),:);
        % do the same for the control cue types
        clear my_field
        my_field = strcat('c_',num2str(n));
        block.(my_field) = time.c(find(time.c(:,5) == n),:);
    end
    
    % then spread these equally over blocks
    clear numx
    clear numc
    numx = (data.numtri_x ./ data.tot_num_blocks) ./ data.num_cues;
    numc = (data.numtri_c ./ data.tot_num_blocks) ./ data.num_cues;
    clear n
    for n = 1:data.tot_num_blocks;
        clear a
        a = strcat('block_',num2str(n));
        clear m
        for m = 1:data.num_cues;
            clear b
            b = strcat('x_',num2str(m));
            block.(a)(((m - 1) .* numx) + 1:m .* numx,:) = block.(b)(((n - 1) .* numx) + 1: n .* numx,:);
        end
        clear m
        for m = 1:data.num_cues;
            % now add in the control trials
            clear b
            b = strcat('c_',num2str(m));
            block.(a)(length(block.(a)(:,1)) + 1:length(block.(a)(:,1)) + numc,:) = block.(b)(((n - 1) .* numc) + 1: n .* numc,:);
        end
        % set the block number in column 8
        block.(a)(:,8) = n;
    end
    
    clear n
    for n = 1:data.tot_num_blocks;
        clear a
        a = strcat('block_',num2str(n));
        for m = 1:2;
            clear b
            b = strcat('block_',num2str(n),'_con_',num2str(m));
            block.(b) = block.(a)(find(block.(a)(:,7) == m),:);
        end
    end
    
    % randomise the blocks but offsetting slightly so control trials are
    % typically later
    clear n
    for n = 1:data.tot_num_blocks;
        clear a
        a = strcat('block_',num2str(n));
        clear b
        b = strcat('rand_',num2str(n));
    
        % randomise with offsets
        block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
        block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));
        block.(b) = sortrows(block.(a),1);
        % check for repetitions of 3 in a row (matched cue and control)
        clear t
        t = 0;
        clear m
        for m = 3:length(block.(b)(:,1));
            if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
               block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
               t = 1;
            end
        end
        % if repeated re-randomise
        while t == 1;
            block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
            block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));    
            block.(b) = sortrows(block.(a),1);
            % check for repetitions
            clear t
            t = 0;
            clear m
            for m = 3:length(block.(b)(:,1));
                if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
                   block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
                   t = 1;
                end
            end
        end
    end
    
    
    % now concatenate all the blocks into a single run
    clear n
    total.whole_run = block.rand_1;
    for n = 2:data.tot_num_blocks
        clear a
        a = strcat('rand_',num2str(n));
        total.whole_run(length(total.whole_run(:,1)) + 1:length(total.whole_run(:,1)) +...
        ((data.tot_num_trials ./ data.tot_num_blocks)),:) = block.(a);
    end
    
    
    
    % then make this run continuous and in seconds
    % first set the respective trial length
    clear n
    for n = 1:length(total.whole_run(:,1));
        total.whole_run(n,9) = data.trilen .* 1000;
    end
    % then make these cumulative
    clear n
    for n = 2:length(total.whole_run(:,1));
        total.whole_run(n,9) = total.whole_run(n,9) + total.whole_run(n - 1,9);
    end
    
    % now make the trial times cumulative
    clear n
    total.run2(1,:) = total.whole_run(1,:);
    for n = 2:length(total.whole_run(:,1));
        total.run2(n,:) = total.whole_run(n,:);
        total.run2(n,2:4) = total.run2(n,2:4) + total.run2(n-1,9);
    end
    
    
    % convert to seconds
    total.run2(:,2:4) = total.run2(:,2:4) ./ 1000;
    
    
    % now check to ensure there are always more or an equal number of experimental
    % trials to control trials, to make the dynamic control condition work.
    clear n
    for n = 1:data.num_cues;
        clear a
        a = num2str(n);
        dynamic.(strcat('cue_',a)) = total.run2(find(total.run2(:,5) == n),:);
    end
    
    clear aa
    aa = 0;
    clear n
    clear m
    for m = 1:data.num_cues;
        mst = num2str(m);
        clear count
        count = 0;
        for n = 1:length(dynamic.(strcat('cue_',mst))(:,1));
            if dynamic.(strcat('cue_',mst))(n,7) == 1;
                count = count + 1;
            elseif dynamic.(strcat('cue_',mst))(n,7) == 2;
                count = count - 1;
            end
            if count < 0;
                aa = 1;
            end
        end
    end
    
    % catch any incidence of the number of controls exceeding the number of
    % experimental, and re randomise until fixed
    while aa ~= 0;
        % randomise the blocks but offsetting slightly so control trials are
        % typically later
        clear n
        for n = 1:data.tot_num_blocks;
            clear a
            a = strcat('block_',num2str(n));
            clear b
            b = strcat('rand_',num2str(n));
            block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
            block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));    
            block.(b) = sortrows(block.(a),1);
            % check for repetitions of 3 in a row (matched cue and control)
            clear t
            t = 0;
            clear m
            for m = 3:length(block.(b)(:,1));
                if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
                   block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
                   t = 1;
                end
            end
            % if repeated re-randomise
            while t == 1;
                block.(a)(1:data.numtri_x ./ data.tot_num_blocks,1) = (100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2);
                block.(a)((data.numtri_x ./ data.tot_num_blocks) + 1:length(block.(a)(:,1)),1) = data.offset + ((100 - data.offset) .* rand(1,length(block.(a)(:,1)) ./ 2));    
                block.(b) = sortrows(block.(a),1);
                % check for repetitions
                clear t
                t = 0;
                clear m
                for m = 3:length(block.(b)(:,1));
                    if block.(b)(m,5) == block.(b)(m-1,5) & block.(b)(m,5) == block.(b)(m-2,5) & ...
                       block.(b)(m,7) == block.(b)(m-1,7) & block.(b)(m,7) == block.(b)(m-2,7);
                       t = 1;
                    end
                end
            end
        end
        
        
        % now concatenate all the blocks into a single run
        clear n
        total.whole_run = block.rand_1;
        for n = 2:data.tot_num_blocks
            clear a
            a = strcat('rand_',num2str(n));
            total.whole_run(length(total.whole_run(:,1)) + 1:length(total.whole_run(:,1)) +...
            ((data.tot_num_trials ./ data.tot_num_blocks)),:) = block.(a);
        end
        
        
        
        % then make this run continuous and in seconds
        % first set the respective trial length
        clear n
        for n = 1:length(total.whole_run(:,1));
            total.whole_run(n,9) = data.trilen .* 1000;
        end
        % then make these cumulative
        clear n
        for n = 2:length(total.whole_run(:,1));
            total.whole_run(n,9) = total.whole_run(n,9) + total.whole_run(n - 1,9);
        end
        
        % now make the trial times cumulative
        clear n
        total.run2(1,:) = total.whole_run(1,:);
        for n = 2:length(total.whole_run(:,1));
            total.run2(n,:) = total.whole_run(n,:);
            total.run2(n,2:4) = total.run2(n,2:4) + total.run2(n-1,9);
        end
        
        
        % convert to seconds
        total.run2(:,2:4) = total.run2(:,2:4) ./ 1000;
        
        
        % now check to ensure there are always more or an equal number of experimental
        % trials to control trials, to make the dynamic control condition work.
        clear n
        for n = 1:data.num_cues;
            clear a
            a = num2str(n);
            dynamic.(strcat('cue_',a)) = total.run2(find(total.run2(:,5) == n),:);
        end
        
        clear aa
        aa = 0;
        clear n
        clear m
        for m = 1:data.num_cues;
            mst = num2str(m);
            clear count
            count = 0;
            for n = 1:length(dynamic.(strcat('cue_',mst))(:,1));
                if dynamic.(strcat('cue_',mst))(n,7) == 1;
                    count = count + 1;
                elseif dynamic.(strcat('cue_',mst))(n,7) == 2;
                    count = count - 1;
                end
                if count < 0;
                    aa = 1;
                end
            end
        end
    end
    
    "dynamic control condition ready"
    
    % need to consider conditions of interest
    clear n
    for n = 1:data.num_cues;
        clear a
        a = strcat('cue_',num2str(n));
        cond.x.(a) = dynamic.(a)(find(dynamic.(a)(:,7) == 1),:);
        cond.c.(a) = dynamic.(a)(find(dynamic.(a)(:,7) == 2),:);
        % add in an estimate of the performance within the 10th column, roughly speaking (0 = inc, 1 =
        % cor). Firstly works out the performance odds if memory is perfect
        % (but never dipping below 90% performance as people are never
        % perfect). It then introduces a measure of error proportional to the
        % odds.
        clear m
        for m = 1:length(cond.x.(a)(:,1));
            clear b
            b = rand(1);
            % look at the first trial, as this is pure chance
            if m == 1;
                if b > (100 - (100 ./ (data.num_targets - (m - 1)))) ./ 100;
                    cond.x.(a)(m,10) = 1;
                    cond.c.(a)(m,10) = 1;
                else
                    cond.x.(a)(m,10) = 0;
                    cond.c.(a)(m,10) = 0;
                end
            % then look at all subsequent trials and make the probability based
            % upon past performance
            else
                % looks at instances of there being at least 2 options left to
                % guess between, and not having got the correct answer yet
                if m < data.num_targets & sum(cond.x.(a)(1:m,10)) < 1;
                    % I work out the odds of getting it right based upon
                    % perfect recall, then add 2.5 multiplied by the trial
                    % number as the degree of error (which I set to increase as
                    % the trial number increases in order to account for having
                    % more incorrect optiosn to recall. E.g. it is easy to
                    % remember not the far right target, but harder to recall
                    % not the far right and middle. Also over trials the number
                    % of other bits of information in other trials increases,
                    % altering the difficulty).
                    if b > ((100 - (100 ./ (data.num_targets - (m - 1)))) + (2.5 .* m)) ./ 100;
                        cond.x.(a)(m,10) = 1;
                        cond.c.(a)(m,10) = 1;
                    else
                        cond.x.(a)(m,10) = 0;
                        cond.c.(a)(m,10) = 0;
                    end
                    % specifies what happens when there is just one option left
                    % statistically (assumes of course that we had no error
                    % based repetition) either through odds, or through having
                    % found the correct answer once already.
                else
                    if b > (data.performance - (m ./ 100));
                        cond.x.(a)(m,10) = 1;
                        cond.c.(a)(m,10) = 1;
                    else
                        cond.x.(a)(m,10) = 0;
                        cond.c.(a)(m,10) = 0;
                    end
                end
            end
        end
    
    
    
        % now classify into the relevant trial types
        % 1 = the error in error-correct pairs
        % 2 = the correct in error-correct pairs
        % 3 = the initial correct in correct-correct pairs
        % 4 = the second correct in correct-correct pairs
        % 5 = all remaining errors
        % 6 = all remaining correct
        % then this repeats through the control trials
        clear m
        cond.x.(a)(:,11) = 999;
        for m = 2:length(cond.x.(a)(:,1));
            % isolate the first loop as we needn't worry about m-2 here
            if m == 2;
                if cond.x.(a)(m-1,10) == 0 & cond.x.(a)(m,10) == 1;
                    if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                        % error before correct
                        cond.x.(a)(m-1,11) = 1;
                        % correct after error
                        cond.x.(a)(m,11) = 2;
                    end
                elseif cond.x.(a)(m-1,10) == 1 & cond.x.(a)(m,10) == 1;
                    if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                        % correct before correct
                        cond.x.(a)(m-1,11) = 3;
                        % correct after correct
                        cond.x.(a)(m,11) = 4;
                    end
                end
                
                % look at all loops from the 2nd onwards where m-3 matters (as
                % we cannot use 0-1 trials which are 0-0-1
            else
                if cond.x.(a)(m-2,10) == 1 & cond.x.(a)(m-1,10) == 0 & cond.x.(a)(m,10) == 1;
                    if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                        % error before correct
                        cond.x.(a)(m-1,11) = 1;
                        % correct after error
                        cond.x.(a)(m,11) = 2;
                    end
                    % and we cannot use 1-1 trials which are 0-1-1 due to the
                    % removal of the 0-0-1 trials (without this removal 0-1-1
                    % would be impossible as it would have been a 0-1 trial)
                elseif cond.x.(a)(m-2,10) == 1 & cond.x.(a)(m-1,10) == 1 & cond.x.(a)(m,10) == 1;
                    if cond.x.(a)(m-1,11) == 999 & cond.x.(a)(m,11) == 999;
                        % correct before correct
                        cond.x.(a)(m-1,11) = 3;
                        % correct after correct
                        cond.x.(a)(m,11) = 4;
                    end
                end
            end
        end
        cond.x.(a)(find(cond.x.(a)(:,11) == 999 & cond.x.(a)(:,10) == 0),11) = 5;
        cond.x.(a)(find(cond.x.(a)(:,11) == 999 & cond.x.(a)(:,10) == 1),11) = 6;
        cond.c.(a)(:,11) = cond.x.(a)(:,11) + 6;
    end
    
    % loop through each cue in each condition:
    % IN THE 11th COLUMN
    % 1 = x err-cor 1st
    % 2 = x err-cor 2nd
    % 3 = x cor-cor 1st
    % 4 = x cor-cor 2nd
    % 5 = x remaining err
    % 6 = x remaining cor
    % 7 = c err-cor 1st
    % 8 = c err-cor 2nd
    % 9 = c cor-cor 1st
    % 10 = c cor-cor 2nd
    % 11 = c remaining err
    % 12 = c remaining cor
    
    total.run3 = [cond.x.cue_1; cond.c.cue_1];
    for n = 2:data.num_cues;
        total.run3 = [total.run3; eval(strcat('cond.x.cue_',num2str(n))); eval(strcat('cond.c.cue_',num2str(n)))]
    end
    % next organise by 2nd column
    total.run3 = sortrows(total.run3,2);
    
    totals(1) = length(find(total.run3(:,11) == 1));
    totals(2) = length(find(total.run3(:,11) == 2));
    totals(3) = length(find(total.run3(:,11) == 3));
    totals(4) = length(find(total.run3(:,11) == 4));
    totals(5) = length(find(total.run3(:,11) == 5));
    totals(6) = length(find(total.run3(:,11) == 6));
    
    
    % load the HRFc function
    data.hrfc = importdata('HRFc.mat')';
    % check how many cells per second
    data.sec = length(data.hrfc) ./ 32.0125;
    % calculate the length of the design matrix in cells
    clear x
    x = max(max(total.run2(:,4)));
    clear y
    y = ceil(x .* data.sec) + length(data.hrfc);
    
    % create the faux design matrix
    cond.design(1:y,1:data.num_regressors) = 0;
    
    % create the regressors
    clear n
    for n = 1:12;
        clear a
        a = strcat('con_',num2str(n));
        cond.(a) = total.run3(find(total.run3(:,11) == n),2);
        clear m
        for m = 1:length(cond.(a));
            clear x
            x = ceil(cond.(a)(m) .* data.sec);
            cond.design(x:x+259,n) = cond.design(x:x+259,n) + data.hrfc;
        end
    end
    
    % do the rest
    clear m
    for m = 1:length(total.run3(:,1));
        % if experimental
        if total.run3(m,7) == 1 & total.run3(m,5) < 4;
            % target
            clear x
            x = ceil(total.run3(m,3) .* data.sec);
            cond.design(x:x+259,13) = cond.design(x:x+259,13) + data.hrfc;
        elseif total.run3(m,7) == 1 & total.run3(m,5) > 3 & total.run3(m,5) < 7;
            % target
            clear x
            x = ceil(total.run3(m,3) .* data.sec);
            cond.design(x:x+259,14) = cond.design(x:x+259,14) + data.hrfc;
        elseif total.run3(m,7) == 1 & total.run3(m,5) > 6;
            % target
            clear x
            x = ceil(total.run3(m,3) .* data.sec);
            cond.design(x:x+259,15) = cond.design(x:x+259,15) + data.hrfc;
        % control
        elseif total.run3(m,7) == 2 & total.run3(m,5) < 4;
            % target
            clear x
            x = ceil(total.run3(m,3) .* data.sec);
            cond.design(x:x+259,16) = cond.design(x:x+259,16) + data.hrfc;
        elseif total.run3(m,7) == 2 & total.run3(m,5) > 3 & total.run3(m,5) < 7;
            % target
            clear x
            x = ceil(total.run3(m,3) .* data.sec);
            cond.design(x:x+259,17) = cond.design(x:x+259,17) + data.hrfc;
        elseif total.run3(m,7) == 2 & total.run3(m,5) > 6;
            % target
            clear x
            x = ceil(total.run3(m,3) .* data.sec);
            cond.design(x:x+259,18) = cond.design(x:x+259,18) + data.hrfc;
        end
        % work through the feedback
        % correct exp first
        if total.run3(m,7) == 1 & total.run3(m,10) == 1;
            clear x
            x = ceil(total.run3(m,4) .* data.sec);
            cond.design(x:x+259,19) = cond.design(x:x+259,19) + data.hrfc;
        % then incorrect exp
        elseif total.run3(m,7) == 1 & total.run3(m,10) == 0;
            clear x
            x = ceil(total.run3(m,4) .* data.sec);
            cond.design(x:x+259,20) = cond.design(x:x+259,20) + data.hrfc;
        % then correct con
        elseif total.run3(m,7) == 2 & total.run3(m,10) == 1;
            clear x
            x = ceil(total.run3(m,4) .* data.sec);
            cond.design(x:x+259,21) = cond.design(x:x+259,21) + data.hrfc;
        % then incorrect con
        elseif total.run3(m,7) == 2 & total.run3(m,10) == 0;
            clear x
            x = ceil(total.run3(m,4) .* data.sec);
            cond.design(x:x+259,22) = cond.design(x:x+259,22) + data.hrfc;
        end
    end
    
    % EXPERIMENTAL
    % 1 = the error in error-correct pairs
    % 2 = the correct in error-correct pairs
    % 3 = the initial correct in correct-correct pairs
    % 4 = the second correct in correct-correct pairs
    % 5 = all remaining errors
    % 6 = all remaining correct
    % CONTROL
    % 7 = the error in error-correct pairs
    % 8 = the correct in error-correct pairs
    % 9 = the initial correct in correct-correct pairs
    % 10 = the second correct in correct-correct pairs
    % 11 = all remaining errors
    % 12 = all remaining correct
    % REMAINING
    % 13 = X targ 1:3
    % 14 = X targ 4:6
    % 15 = X targ 7:10
    % 16 = C targ 1:3
    % 17 = C targ 4:6
    % 18 = C targ 7:10
    % 19 = X feed cor
    % 20 = X feed incor
    % 21 = C feed cor
    % 22 = C feed incor
    
    
    % create a correlation matrix
    cond.correlate = corrcoef(cond.design);
    
    % remove 1s
    clear n
    for n = 1:length(cond.correlate(:,1));
        cond.correlate(n,n) = 0;
    end
    
    clear max_j
    cond.max_correlate = max(max(abs(cond.correlate(1:12,[1:4,7:10]))));
    total.duration = max(max(total.run2(:,4))) ./ 60;
    cond.max_correlate_all = max(max(abs(cond.correlate(:,[1:4,7:10]))))

    % load up the currently best r value
    old = importdata('cond.mat');
    old.max_correlate_all
    old.max_correlate

    % count runs
    load('counter.mat');
    counter = counter + 1;
    save counter counter


    % if my new best r value is lower, then save this
    if cond.max_correlate_all < old.max_correlate_all;
        save block block
        save cond cond
        save time time
        save total total
        save totals totals
        save dynamic dynamic
        'Improvement!'
    else
        'No good....'
    end
end 
