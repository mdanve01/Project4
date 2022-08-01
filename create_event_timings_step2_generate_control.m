clear all
cd('F:/Experiment_4/create_run');
load('total.mat');
load('data.mat');
% create an ordered column
clear n
for n = 1:length(total.whole_run(:,1));
    total.whole_run(n,1) = n;
end

% sort by cue then condition
total.whole_run = sortrows(total.whole_run, 5);
total.whole_run = sortrows(total.whole_run, 7);

% find all experimental trials and set column 6 to 0, as there is no
% specific target allocation needed yet
clear n
for n = 1:length(total.whole_run(:,1));
    if total.whole_run(n,7) == 1;
        total.whole_run(n,6) = 0;
    end
end

% work out the number of trials pertaining to a specifc cue in the control condition
clear m
for m = 1:data.num_cues;
    clear n
    n = strcat('cue_',num2str(m));
    newdata.num_events.(n) = length(find(total.whole_run(:,7) == 2 & total.whole_run(:,5) == 1));
end

% create a vector of possible target locations which matches the number of
% cue repetitions in the control condtion
clear n
clear o
for o = 1:data.num_cues;
    clear num
    num = strcat('cue_',num2str(o));
    for n = 1:ceil(newdata.num_events.(num) ./ data.num_targets);
        try
            for m = 1:data.num_targets;
                newdata.allocations.(num)(m + (data.num_targets .* (n - 1)),1) = m;
            end
        end
    end
end

% now randomise this vector and apply to each run
clear n
for n = 1:data.num_cues;
    clear num
    num = strcat('cue_',num2str(n));
    % correct for length of list
    newdata.allocations.(num)(newdata.allocations.(num)(length(find(total.whole_run(:,5) == n & total.whole_run(:,7) == 2)) + 1: ...
        length(newdata.allocations.(num)(:,1))),:) = [];
    % randomise vector
    newdata.allocations.(num)(:,2) = rand(1,length(newdata.allocations.(num)(:,1)));
    newdata.allocations.(num) = sortrows(newdata.allocations.(num), 2);
    % apply to the relevant cue in the control condition
    total.whole_run(find(total.whole_run(:,5) == n & total.whole_run(:,7) == 2),6) = newdata.allocations.(num)(:,1);
end

% re-order the run
total.whole_run = sortrows(total.whole_run,1);

% now check whether there are repetitions, should have no repetitions
% beyond twice
clear t
clear n
newdata.check = total.whole_run(find(total.whole_run(:,7) == 2),:);
newdata.check = sortrows(newdata.check,5);
t = 0;
for n = 3:length(newdata.check(:,1));
    if newdata.check(n,5) == newdata.check(n-1,5) & newdata.check(n,6) == newdata.check(n-1,6) & ...
            newdata.check(n,5) == newdata.check(n-2,5) & newdata.check(n,6) == newdata.check(n-2,6);
    t = 1;
    end
end

% loop through until the control condition never repeats the same pairing
% location on sequential trials.
while t == 1;
    % now randomise this vector and apply to each run
    clear n
    for n = 1:data.num_cues;
        clear num
        num = strcat('cue_',num2str(n));
        % randomise vector
        newdata.allocations.(num)(:,2) = rand(1,length(newdata.allocations.(num)(:,1)));
        newdata.allocations.(num) = sortrows(newdata.allocations.(num), 2);
        % apply to the relevant cue in the control condition
        total.whole_run(find(total.whole_run(:,5) == n & total.whole_run(:,7) == 2),6) = newdata.allocations.(num)(:,1);
    end

    % re-order the run
    total.whole_run = sortrows(total.whole_run,1);

    % now check whether there are repetitions, should have no repetitions
    % beyond twice
    clear t
    clear n
    newdata.check = total.whole_run(find(total.whole_run(:,7) == 2),:);
    newdata.check = sortrows(newdata.check,5);
    t = 0;
    for n = 3:length(newdata.check(:,1));
        if newdata.check(n,5) == newdata.check(n-1,5) & newdata.check(n,6) == newdata.check(n-1,6) & ...
                newdata.check(n,5) == newdata.check(n-2,5) & newdata.check(n,6) == newdata.check(n-2,6);
        t = 1;
        end
    end
end

newdata.whole_run = total.whole_run;

% set the experimental targets
clear n
for n = 1:data.num_cues;
    if n <= data.num_targets;
        newdata.whole_run(find(newdata.whole_run(:,7) == 1 & newdata.whole_run(:,5) == n),6) = n;
    elseif n <= data.num_targets .* 2;
        newdata.whole_run(find(newdata.whole_run(:,7) == 1 & newdata.whole_run(:,5) == n),6) = n - data.num_targets;
    elseif n <= data.num_targets .* 3;
        newdata.whole_run(find(newdata.whole_run(:,7) == 1 & newdata.whole_run(:,5) == n),6) = n - (data.num_targets .* 2);
    else
        newdata.whole_run(find(newdata.whole_run(:,7) == 1 & newdata.whole_run(:,5) == n),6) = n - (data.num_targets .* 3);
    end
end
% newdata.whole_run(find(newdata.whole_run(:,7) == 1 & newdata.whole_run(:,5) == data.num_cues),6) = 2;

newdata.EB(:,1) = newdata.whole_run(:,2);
newdata.EB(:,2) = newdata.whole_run(:,2) + data.cue_spec;
newdata.EB(:,3) = newdata.whole_run(:,3);
newdata.EB(:,4) = newdata.whole_run(:,3) + data.targ_spec;
newdata.EB(:,5) = newdata.whole_run(:,4);
newdata.EB(:,6) = newdata.whole_run(:,4) + data.feed_spec;
newdata.EB(:,7) = newdata.whole_run(:,5);
newdata.EB(:,8) = newdata.whole_run(:,6);
newdata.EB(:,9) = newdata.whole_run(:,7);
newdata.EB(:,10) = max(newdata.EB(:,6)) + 33;


save finaldata newdata
