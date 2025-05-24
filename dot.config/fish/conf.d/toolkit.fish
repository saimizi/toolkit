function reboot
    set result (string match -i -r '^\-\-help$' -- $argv | uniq)
    if test "x$result" != "x"
        /sbin/reboot --help
        return
    end

    set confirm (read -P "Are you sure to reboot? ")
    set result (string match -i -r '^(y|yes)$' $confirm | uniq)

    if test "x$result" != "x"
        /sbin/reboot $argv
    else
        echo "Reboot cancelled."
    end
end

function shutdown
    set result (string match -i -r '^\-\-help$' -- $argv | uniq)
    if test "x$result" != "x"
        /sbin/reboot --help
        return
    end

    set confirm (read -P "Are you sure to shutdown? ")
    set result (string match -i -r '^(y|yes)$' $confirm | uniq)

    if test "x$result" != "x"
        /sbin/shutdown $argv
    else
        echo "Shutdown cancelled."
    end
end

function need_reboot
    if test -f /var/run/reboot-required
        cat /var/run/reboot-required
    end
end

function nocolor
    if test "x$argv[1]" != "x"
        cat $argv[1] |  sed -r "s:\x1B\[[0-9;]*[mK]::g"
    else
        cat /dev/stdin |  sed -r "s:\x1B\[[0-9;]*[mK]::g"
    end
end

function noCtrlM 
    if test "x$argv[1]" != "x"
        cat $argv[1] | sed -r "s:::g"
    else
        cat /dev/stdin  | sed -r "s:::g"
    end
end

function docker_clean_none_images
	for t in  (docker images | grep none | awk '{print $3}');
		docker rmi  $t;
	end	
end
