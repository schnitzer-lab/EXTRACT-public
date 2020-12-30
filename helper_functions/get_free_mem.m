function freemem = get_free_mem
    if ismac
        [~, m]=unix('vm_stat | grep active');
        spaces=strfind(m,' ');
        freemem = str2double(m(spaces(end):end))*4096;
    elseif isunix
        [~, w] = unix('free | grep Mem');
    stats = str2double(regexp(w, '[0-9]*', 'match'));
    freemem = (stats(end)) * 1e3;
    elseif ispc
        [~, sys] = memory;
        freemem = sys.PhysicalMemory.Available;
    end
end