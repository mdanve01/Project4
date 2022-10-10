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

    % 1 = cue all saccade 10
    % 2 = cue all saccade 2
    % 3 = cue all saccade 3
    % 4 = targ1or0 with feed0
    % 5 = targ2
    % 6 = targ3
    % 7 = feed2 exp
    % 8 = feed2 con
    % 9 = feed1 exp
    % 10 = feed1 con



    % cue correct saccade 10
    clear nn
    clear reg
    reg = sortrows([design.exp.cue2only(find(design.exp.cue2only(:,5) < 2),8); design.con.cue2only(find(design.con.cue2only(:,5) < 2),8); design.exp.cue2onlyNOT(find(design.exp.cue2onlyNOT(:,5) < 2),8); design.con.cue2onlyNOT(find(design.con.cue2onlyNOT(:,5) < 2),8)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m) = cond.design(x:x+256,m) + data.hrf(:,m);
        end
    end

    % cue correct saccade 2 MAKE LIKE CUE CORRECT SACCADE 3
    clear nn
    clear reg
    reg = sortrows([design.exp.cue2only(find(design.exp.cue2only(:,5) == 2),8); design.con.cue2only(find(design.con.cue2only(:,5) == 2),8); design.exp.cue2onlyNOT(find(design.exp.cue2onlyNOT(:,5) == 2),8); design.con.cue2onlyNOT(find(design.con.cue2onlyNOT(:,5) == 2),8)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 3) = cond.design(x:x+256,m + 3) + data.hrf(:,m);
        end
    end

    % cue correct saccade 3
    clear nn
    clear reg
    reg = sortrows([design.exp.cue2only(find(design.exp.cue2only(:,5) == 3),8); design.con.cue2only(find(design.con.cue2only(:,5) == 3),8); design.exp.cue2onlyNOT(find(design.exp.cue2onlyNOT(:,5) == 3),8); design.con.cue2onlyNOT(find(design.con.cue2onlyNOT(:,5) == 3),8)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 6) = cond.design(x:x+256,m + 6) + data.hrf(:,m);
        end
    end

    % target1
    clear nn
    clear reg
    reg = sortrows([design.combined.targ1or0(:,11); design.combined.feed0(:,14)],1);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 9) = cond.design(x:x+256,m + 9) + data.hrf(:,m);
        end
    end

    % target2
    clear nn
    for nn = 1:length(design.combined.targ2(:,11));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.combined.targ2(nn,11) .* data.sec);
            cond.design(x:x+256,m + 12) = cond.design(x:x+256,m + 12) + data.hrf(:,m);
        end
    end    
    
    % target3
    clear nn
    for nn = 1:length(design.combined.targ3(:,11));
        clear m
        for m = 1:3;
            clear x
            x = ceil(design.combined.targ3(nn,11) .* data.sec);
            cond.design(x:x+256,m + 15) = cond.design(x:x+256,m + 15) + data.hrf(:,m);
        end
    end    

    % exp feedback correct
    clear nn
    clear reg
    reg = design.exp.feed2(:,14);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 18) = cond.design(x:x+256,m + 18) + data.hrf(:,m);
        end
    end

    % con feedback correct
    clear nn
    clear reg
    reg = design.con.feed2(:,14);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 21) = cond.design(x:x+256,m + 21) + data.hrf(:,m);
        end
    end

    % exp feedback incorrect
    clear nn
    clear reg
    reg = design.exp.feed1(:,14);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 24) = cond.design(x:x+256,m + 24) + data.hrf(:,m);
        end
    end

    % con feedback incorrect
    clear nn
    clear reg
    reg = design.con.feed1(:,14);
    for nn = 1:length(reg);
        clear m
        for m = 1:3;
            clear x
            x = ceil(reg(nn) .* data.sec);
            cond.design(x:x+256,m + 27) = cond.design(x:x+256,m + 27) + data.hrf(:,m);
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

    cond.max_interest = max(max(abs(cond.correlate(19:30,:))));

    table(n,1) = sub(n);
    table(n,2) = cond.max_correlate;
    table(n,3) = cond.max_interest;

    save table table

    cd(strcat('C:/Users/mdanv/OneDrive/PhD_Stuff/Experiment_4/data/Version8_10Rules_deploy2/results/p',num2str(sub(n))));
    save cond cond
    
end

figure(1)
imagesc(cond.correlate);
colorbar

