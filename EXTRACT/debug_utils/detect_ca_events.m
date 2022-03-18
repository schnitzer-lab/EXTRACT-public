function event_frames = detect_ca_events(trace,threshold,do_smoothing, varargin)
% Extract maximum points in the trace as candidate events
% varargin : 1 optional argument. Set it to 1 if you want to plot the
% output
filt_len=3;
trace = double(full(trace));


if ~exist('do_smoothing', 'var')
    do_smoothing = true;
end

num_frames = length(trace);

alpha =2.5;
f_width = 6;
f = gausswin(f_width,alpha);
f = [0.1,0.4,1,0.4,0.1];
f = f/sum(f);
if do_smoothing
    smooth_trace = medfilt1(trace, filt_len);
    smooth_trace = conv(smooth_trace,f);
    smooth_trace = smooth_trace(f_width/2:end-f_width/2);
else
    smooth_trace = trace;
end

% smooth_trace = medfilt1(smooth_trace,filt_len);
diff_trace = smooth_trace;%diff(smooth_trace);
diff_trace(diff_trace<0)=0;
diff_trace = [0, diff_trace];

thresh1 = threshold *max(smooth_trace);% mad(diff_trace(diff_trace>0),1);;
thresh2 = threshold *max(diff_trace);
warning off;
% [~,event_frames] = findpeaks(smooth_trace,'minpeakheight',thresh1);
[event_frames, ~] = peakseek(smooth_trace, 10, thresh1);
warning on;
% Filter by diff
% diff_at_peaks = diff_trace(event_frames);
% event_frames(diff_at_peaks<thresh2) = [];

%go back to the original trace and spot the maximum
max_shift = 2;
for k = 1:length(event_frames)
    coarse_event = event_frames(k);
    go_back = min(max_shift,coarse_event-1);
    go_forward = min(max_shift,num_frames-coarse_event);
    [~,idx_max] = max(trace((coarse_event-go_back):(coarse_event+go_forward)));
    event_frames(k) = idx_max+coarse_event-go_back-1;
end
event_frames(trace(event_frames)==0) = [];

if ~isempty(varargin)
    if varargin{1} == 1
        spikes_vec = zeros(1,length(diff_trace));
        spikes_vec(event_frames) = 1;
        plot(diff_trace/max(diff_trace));
        hold on;
        stem(event_frames, threshold*ones(1, length(event_frames)), 'Linestyle', 'none');
        plot(threshold*ones(1,length(diff_trace)),'r')
        plot(trace/max(trace),'--m');
        hold off
        for k = 1:length(event_frames)
            text(event_frames(k),double(thresh1*1.1),num2str(k))
        end
    end
end