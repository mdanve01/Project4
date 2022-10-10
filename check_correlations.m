clear all
sub = [803 804 808 809 810 811 812];

clear n
for n = 1:length(sub);

    cd(strcat('C:/Users/mdanv/OneDrive/PhD_Stuff/Experiment_4/data/Version8_10Rules_deploy2/results/p',num2str(sub(n))));
    design = importdata('design.mat');

    % load the HRF function
    cd('C:/Users/mdanv/OneDrive/PhD_Stuff/Experiment_4');
    data.hrf = importdata('hrftd.mat');
    % check how many cells per second
    data.sec = length(data.hrf(:,1)) ./ 32.125;
    % calculate the length of the design matrix in cells
    clear x
    x = max([design.combined.feed1or0(:,14); design.combined.feed2(:,14)]);
    clear y
    y = ceil(x .* data.sec) + length(data.hrf(:,1));

    % create the faux design matrix
    cond.design(1:y,1:33) = 0;

    % loop through each variable and convolve with the HRF

    % 1 = exp cue correct
    % 2 = con cue correct
    % 3 = exp cue incorrect
    % 4 = con cue incorrect
    % 5 = junk cueElse and missed targ/feed
    % 6 = target one
    % 7 = target two
    % 8 = target three
    % 9 = feedback saccade 1
    % 10 = feedback saccade 2
    % 11 = feedback saccade 3


    % exp cue correct
    clear nn
    for nn = 1:length(design.orig.exp.cue2(:,8));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.orig.exp.cue2(nn,8) .* data.sec);
            cond.design(x:x+256,m) = cond.design(x:x+256,m) + data.hrf(:,m);
        end
    end

    % con cue correct
    clear nn
    for nn = 1:length(design.orig.con.cue2(:,8));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.orig.con.cue2(nn,8) .* data.sec);
            cond.design(x:x+256,m + 3) = cond.design(x:x+256,m + 3) + data.hrf(:,m);
        end
    end

    % exp cue incorrect
    clear nn
    for nn = 1:length(design.orig.exp.cue1(:,8));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.orig.exp.cue1(nn,8) .* data.sec);
            cond.design(x:x+256,m + 6) = cond.design(x:x+256,m + 6) + data.hrf(:,m);
        end
    end

    % con cue incorrect
    clear nn
    for nn = 1:length(design.orig.con.cue1(:,8));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.orig.con.cue1(nn,8) .* data.sec);
            cond.design(x:x+256,m + 9) = cond.design(x:x+256,m + 9) + data.hrf(:,m);
        end
    end

    % junk
    clear nn
    clear junk
    junk = sortrows([design.orig.exp.cueElse(:,8); design.orig.con.cueElse(:,8);...
            design.combined.targ0(:,11); design.combined.feed0(:,14)],1);
    for nn = 1:length(junk);
        clear m
        for m = 1:3;
            clear x
            x = ceil(junk(nn) .* data.sec);
            cond.design(x:x+256,m + 12) = cond.design(x:x+256,m + 12) + data.hrf(:,m);
        end
    end

    % target1
    clear nn
    for nn = 1:length(design.combined.targ1(:,11));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.combined.targ1(nn,11) .* data.sec);
            cond.design(x:x+256,m + 15) = cond.design(x:x+256,m + 15) + data.hrf(:,m);
        end
    end

    % target2
    clear nn
    for nn = 1:length(design.combined.targ2(:,11));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.combined.targ2(nn,11) .* data.sec);
            cond.design(x:x+256,m + 18) = cond.design(x:x+256,m + 18) + data.hrf(:,m);
        end
    end    
    
    % target3
    clear nn
    for nn = 1:length(design.combined.targ3(:,11));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.combined.targ3(nn,11) .* data.sec);
            cond.design(x:x+256,m + 21) = cond.design(x:x+256,m + 21) + data.hrf(:,m);
        end
    end    

    % feedback
    clear nn
    clear reg
    reg = sortrows([design.combined.feed2(find(design.combined.feed2(:,4 == 1)),14); design.combined.feed1(find(design.combined.feed1(:,4 == 1)),14)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 24) = cond.design(x:x+256,m + 24) + data.hrf(:,m);
        end
    end

    % feedback
    clear nn
    clear reg
    reg = sortrows([design.combined.feed2(find(design.combined.feed2(:,4 == 2)),14); design.combined.feed1(find(design.combined.feed1(:,4 == 2)),14)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 27) = cond.design(x:x+256,m + 27) + data.hrf(:,m);
        end
    end

    % feedback
    clear nn
    clear reg
    reg = sortrows([design.combined.feed2(find(design.combined.feed2(:,4 == 3)),14); design.combined.feed1(find(design.combined.feed1(:,4 == 3)),14)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 30) = cond.design(x:x+256,m + 30) + data.hrf(:,m);
        end
    end

    
    % create a correlation matrix
    cond.correlate = corrcoef(cond.design);

    % remove 1s
    clear nn
    for nn = 1:length(cond.correlate(:,1));
        cond.correlate(nn,nn) = 0;
    end

    clear max_j
    cond.max_correlate = max(max(abs(cond.correlate)));

    cond.max_interest = max(max(abs(cond.correlate(1:12,:))));

    table(n,1) = sub(n);
    table(n,2) = cond.max_correlate;
    table(n,3) = cond.max_interest;

    save table table

    cd(strcat('C:/Users/mdanv/OneDrive/PhD_Stuff/Experiment_4/data/Version8_10Rules_deploy2/results/p',num2str(sub(n))));
    save cond cond
    
end



