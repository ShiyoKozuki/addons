addon.name      = 'deadzone';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Alters controller deadzone';
addon.link      = 'https://ashitaxi.com/';

require('common');

local dInput_DeadZone = 42;
local xInput_DeadZone = 10837;

ashita.events.register('dinput_button', 'dinput_button_cb', function (e)
    if T{0, 4, 8, 12, 16, 20, 24, 28 }:contains(e.button) then
        if e.state < dInput_DeadZone or ((e.state + dInput_DeadZone) > 0xFFFFFFFF) then
            e.state = 0;
        else
            print(e.state);
        end
    end
end);

ashita.events.register('xinput_button', 'xinput_button_cb', function (e)
    if T{ 34, 35, 36, 37 }:contains(e.button) then
        if (math.abs(e.state) < xInput_DeadZone) then
            e.state = 0;
        else
            print(e.state);
        end
    end
end);