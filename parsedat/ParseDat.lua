addon.name      = 'ParseDat';
addon.author    = 'Thorny';
addon.version   = '1.00';
addon.desc      = 'Parses zone message dats';
addon.link      = 'https://github.com/ThornyFFXI/';

require('common');
local ffi = require('ffi');
local clientPath = 'C:\\Ashita 4\\Client\\FINAL FANTASY XI\\';
local pivotPath = 'C:\\Ashita 4\\polplugins\\DATs\\Moos Server\\';
local outputPath = 'C:\\Ashita 4\\parsedatlogs\\%s.txt';

local zoneDats = {
    [1] = 6421, --Phanauet Channel
    [2] = 6422, --Carpenters' Landing
    [3] = 6423, --Manaclipper
    [4] = 6424, --Bibiki Bay
    [5] = 6425, --Uleguerand Range
    [6] = 6426, --Bearclaw Pinnacle
    [7] = 6427, --Attohwa Chasm
    [8] = 6428, --Boneyard Gully
    [9] = 6429, --Pso'Xja
    [10] = 6430, --The Shrouded Maw
    [11] = 6431, --Oldton Movalpolos
    [12] = 6432, --Newton Movalpolos
    [13] = 6433, --Mine Shaft #2716
    [14] = 6434, --Hall of Transference
    [15] = 6435, --Abyssea - Konschtat
    [16] = 6436, --Promyvion - Holla
    [17] = 6437, --Spire of Holla
    [18] = 6438, --Promyvion - Dem
    [19] = 6439, --Spire of Dem
    [20] = 6440, --Promyvion - Mea
    [21] = 6441, --Spire of Mea
    [22] = 6442, --Promyvion - Vahzl
    [23] = 6443, --Spire of Vahzl
    [24] = 6444, --Lufaise Meadows
    [25] = 6445, --Misareaux Coast
    [26] = 6446, --Tavnazian Safehold
    [27] = 6447, --Phomiuna Aqueducts
    [28] = 6448, --Sacrarium
    [29] = 6449, --Riverne - Site #B01
    [30] = 6450, --Riverne - Site #A01
    [31] = 6451, --Monarch Linn
    [32] = 6452, --Sealion's Den
    [33] = 6453, --Al'Taieu
    [34] = 6454, --Grand Palace of Hu'Xzoi
    [35] = 6455, --The Garden of Ru'Hmet
    [36] = 6456, --Empyreal Paradox
    [37] = 6457, --Temenos
    [38] = 6458, --Apollyon
    [39] = 6459, --Dynamis - Valkurm
    [40] = 6460, --Dynamis - Buburimu
    [41] = 6461, --Dynamis - Qufim
    [42] = 6462, --Dynamis - Tavnazia
    [43] = 6463, --Diorama Abdhaljs-Ghelsba
    [44] = 6464, --Abdhaljs Isle-Purgonorgo
    [45] = 6465, --Abyssea - Tahrongi
    [46] = 6466, --Open sea route to Al Zahbi
    [47] = 6467, --Open sea route to Mhaura
    [48] = 6468, --Al Zahbi
    -- [49] = 6469, --none
    [50] = 6470, --Aht Urhgan Whitegate
    [51] = 6471, --Wajaom Woodlands
    [52] = 6472, --Bhaflau Thickets
    [53] = 6473, --Nashmau
    [54] = 6474, --Arrapago Reef
    [55] = 6475, --Ilrusi Atoll
    [56] = 6476, --Periqia
    [57] = 6477, --Talacca Cove
    [58] = 6478, --Silver Sea route to Nashmau
    [59] = 6479, --Silver Sea route to Al Zahbi
    [60] = 6480, --The Ashu Talif
    [61] = 6481, --Mount Zhayolm
    [62] = 6482, --Halvung
    [63] = 6483, --Lebros Cavern
    [64] = 6484, --Navukgo Execution Chamber
    [65] = 6485, --Mamook
    [66] = 6486, --Mamool Ja Training Grounds
    [67] = 6487, --Jade Sepulcher
    [68] = 6488, --Aydeewa Subterrane
    [69] = 6489, --Leujaoam Sanctum
    [70] = 6490, --Chocobo Circuit
    [71] = 6491, --The Colosseum
    [72] = 6492, --Alzadaal Undersea Ruins
    [73] = 6493, --Zhayolm Remnants
    [74] = 6494, --Arrapago Remnants
    [75] = 6495, --Bhaflau Remnants
    [76] = 6496, --Silver Sea Remnants
    [77] = 6497, --Nyzul Isle
    [78] = 6498, --Hazhalm Testing Grounds
    [79] = 6499, --Caedarva Mire
    [80] = 6500, --Southern San d'Oria [S]
    [81] = 6501, --East Ronfaure [S]
    [82] = 6502, --Jugner Forest [S]
    [83] = 6503, --Vunkerl Inlet [S]
    [84] = 6504, --Batallia Downs [S]
    [85] = 6505, --La Vaule [S]
    [86] = 6506, --Everbloom Hollow
    [87] = 6507, --Bastok Markets [S]
    [88] = 6508, --North Gustaberg [S]
    [89] = 6509, --Grauberg [S]
    [90] = 6510, --Pashhow Marshlands [S]
    [91] = 6511, --Rolanberry Fields [S]
    [92] = 6512, --Beadeaux [S]
    [93] = 6513, --Ruhotz Silvermines
    [94] = 6514, --Windurst Waters [S]
    [95] = 6515, --West Sarutabaruta [S]
    [96] = 6516, --Fort Karugo-Narugo [S]
    [97] = 6517, --Meriphataud Mountains [S]
    [98] = 6518, --Sauromugue Champaign [S]
    [99] = 6519, --Castle Oztroja [S]
    [100] = 6520, --West Ronfaure
    [101] = 6521, --East Ronfaure
    [102] = 6522, --La Theine Plateau
    [103] = 6523, --Valkurm Dunes
    [104] = 6524, --Jugner Forest
    [105] = 6525, --Batallia Downs
    [106] = 6526, --North Gustaberg
    [107] = 6527, --South Gustaberg
    [108] = 6528, --Konschtat Highlands
    [109] = 6529, --Pashhow Marshlands
    [110] = 6530, --Rolanberry Fields
    [111] = 6531, --Beaucedine Glacier
    [112] = 6532, --Xarcabard
    [113] = 6533, --Cape Teriggan
    [114] = 6534, --Eastern Altepa Desert
    [115] = 6535, --West Sarutabaruta
    [116] = 6536, --East Sarutabaruta
    [117] = 6537, --Tahrongi Canyon
    [118] = 6538, --Buburimu Peninsula
    [119] = 6539, --Meriphataud Mountains
    [120] = 6540, --Sauromugue Champaign
    [121] = 6541, --The Sanctuary of Zi'Tah
    [122] = 6542, --Ro'Maeve
    [123] = 6543, --Yuhtunga Jungle
    [124] = 6544, --Yhoator Jungle
    [125] = 6545, --Western Altepa Desert
    [126] = 6546, --Qufim Island
    [127] = 6547, --Behemoth's Dominion
    [128] = 6548, --Valley of Sorrows
    [129] = 6549, --Ghoyu's Reverie
    [130] = 6550, --Ru'Aun Gardens
    [131] = 6551, --Mordion Gaol
    [132] = 6552, --Abyssea - La Theine
    [134] = 6554, --Dynamis - Beaucedine
    [135] = 6555, --Dynamis - Xarcabard
    [136] = 6556, --Beaucedine Glacier [S]
    [137] = 6557, --Xarcabard [S]
    [138] = 6558, --Castle Zvahl Baileys [S]
    [139] = 6559, --Horlais Peak
    [140] = 6560, --Ghelsba Outpost
    [141] = 6561, --Fort Ghelsba
    [142] = 6562, --Yughott Grotto
    [143] = 6563, --Palborough Mines
    [144] = 6564, --Waughroon Shrine
    [145] = 6565, --Giddeus
    [146] = 6566, --Balga's Dais
    [147] = 6567, --Beadeaux
    [148] = 6568, --Qulun Dome
    [149] = 6569, --Davoi
    [150] = 6570, --Monastic Cavern
    [151] = 6571, --Castle Oztroja
    [152] = 6572, --Altar Room
    [153] = 6573, --The Boyahda Tree
    [154] = 6574, --Dragon's Aery
    [155] = 6575, --Castle Zvahl Keep [S]
    [156] = 6576, --Throne Room [S]
    [157] = 6577, --Middle Delkfutt's Tower
    [158] = 6578, --Upper Delkfutt's Tower
    [159] = 6579, --Temple of Uggalepih
    [160] = 6580, --Den of Rancor
    [161] = 6581, --Castle Zvahl Baileys
    [162] = 6582, --Castle Zvahl Keep
    [163] = 6583, --Sacrificial Chamber
    [164] = 6584, --Garlaige Citadel [S]
    [165] = 6585, --Throne Room
    [166] = 6586, --Ranguemont Pass
    [167] = 6587, --Bostaunieux Oubliette
    [168] = 6588, --Chamber of Oracles
    [169] = 6589, --Toraimarai Canal
    [170] = 6590, --Full Moon Fountain
    [171] = 6591, --Crawlers' Nest [S]
    [172] = 6592, --Zeruhn Mines
    [173] = 6593, --Korroloka Tunnel
    [174] = 6594, --Kuftal Tunnel
    [175] = 6595, --The Eldieme Necropolis [S]
    [176] = 6596, --Sea Serpent Grotto
    [177] = 6597, --Ve'Lugannon Palace
    [178] = 6598, --The Shrine of Ru'Avitau
    [179] = 6599, --Stellar Fulcrum
    [180] = 6600, --La'Loff Amphitheater
    [181] = 6601, --The Celestial Nexus
    [182] = 6602, --Walk of Echoes
    [183] = 6603, --Maquette Abdhaljs-LegionA
    [184] = 6604, --Lower Delkfutt's Tower
    [185] = 6605, --Dynamis - San d'Oria
    [186] = 6606, --Dynamis - Bastok
    [187] = 6607, --Dynamis - Windurst
    [188] = 6608, --Dynamis - Jeuno
    [190] = 6610, --King Ranperre's Tomb
    [191] = 6611, --Dangruf Wadi
    [192] = 6612, --Inner Horutoto Ruins
    [193] = 6613, --Ordelle's Caves
    [194] = 6614, --Outer Horutoto Ruins
    [195] = 6615, --The Eldieme Necropolis
    [196] = 6616, --Gusgen Mines
    [197] = 6617, --Crawlers' Nest
    [198] = 6618, --Maze of Shakhrami
    [200] = 6620, --Garlaige Citadel
    [201] = 6621, --Cloister of Gales
    [202] = 6622, --Cloister of Storms
    [203] = 6623, --Cloister of Frost
    [204] = 6624, --Fei'Yin
    [205] = 6625, --Ifrit's Cauldron
    [206] = 6626, --Qu'Bia Arena
    [207] = 6627, --Cloister of Flames
    [208] = 6628, --Quicksand Caves
    [209] = 6629, --Cloister of Tremors
    [211] = 6631, --Cloister of Tides
    [212] = 6632, --Gustav Tunnel
    [213] = 6633, --Labyrinth of Onzozo
    [215] = 6635, --Abyssea - Attohwa
    [216] = 6636, --Abyssea - Misareaux
    [217] = 6637, --Abyssea - Vunkerl
    [218] = 6638, --Abyssea - Altepa
    [220] = 6640, --Ship bound for Selbina
    [221] = 6641, --Ship bound for Mhaura
    [222] = 6642, --Provenance
    [223] = 6643, --San d'Oria-Jeuno Airship
    [224] = 6644, --Bastok-Jeuno Airship
    [225] = 6645, --Windurst-Jeuno Airship
    [226] = 6646, --Kazham-Jeuno Airship
    [227] = 6647, --Ship bound for Selbina
    [228] = 6648, --Ship bound for Mhaura
    [230] = 6650, --Southern San d'Oria
    [231] = 6651, --Northern San d'Oria
    [232] = 6652, --Port San d'Oria
    [233] = 6653, --Chateau d'Oraguille
    [234] = 6654, --Bastok Mines
    [235] = 6655, --Bastok Markets
    [236] = 6656, --Port Bastok
    [237] = 6657, --Metalworks
    [238] = 6658, --Windurst Waters
    [239] = 6659, --Windurst Walls
    [240] = 6660, --Port Windurst
    [241] = 6661, --Windurst Woods
    [242] = 6662, --Heavens Tower
    [243] = 6663, --Ru'Lude Gardens
    [244] = 6664, --Upper Jeuno
    [245] = 6665, --Lower Jeuno
    [246] = 6666, --Port Jeuno
    [247] = 6667, --Rabao
    [248] = 6668, --Selbina
    [249] = 6669, --Mhaura
    [250] = 6670, --Kazham
    [251] = 6671, --Hall of the Gods
    [252] = 6672, --Norg
    [253] = 6673, --Abyssea - Uleguerand
    [254] = 6674, --Abyssea - Grauberg
    [255] = 6675, --Abyssea - Empyreal Paradox
    [256] = 85591, --Western Adoulin
    [257] = 85592, --Eastern Adoulin
    [258] = 85593, --Rala Waterways
    [259] = 85594, --Rala Waterways [U]
    [260] = 85595, --Yahse Hunting Grounds
    [261] = 85596, --Ceizak Battlegrounds
    [262] = 85597, --Foret de Hennetiel
    [263] = 85598, --Yorcia Weald
    [264] = 85599, --Yorcia Weald [U]
    [265] = 85600, --Morimar Basalt Fields
    [266] = 85601, --Marjami Ravine
    [267] = 85602, --Kamihr Drifts
    [268] = 85603, --Sih Gates
    [269] = 85604, --Moh Gates
    [270] = 85605, --Cirdas Caverns
    [271] = 85606, --Cirdas Caverns [U]
    [272] = 85607, --Dho Gates
    [273] = 85608, --Woh Gates
    [274] = 85609, --Outer Ra'Kaznar
    [275] = 85610, --Outer Ra'Kaznar [U]
    [276] = 85611, --Ra'Kaznar Inner Court
    [277] = 85612, --Ra'Kaznar Turris
    [279] = 85614, --Walk of Echoes [P2]
    [280] = 85615, --Mog Garden
    [281] = 85616, --Leafallia
    [282] = 85617, --Mount Kamihr
    [283] = 85618, --Silver Knife
    [284] = 85619, --Celennia Memorial Library
    [285] = 85620, --Feretory
    [287] = 85622, --Maquette Abdhaljs-LegionB
    [288] = 85623, --Escha - Zi'Tah
    [289] = 85624, --Escha - Ru'Aun
    [290] = 85625, --Desuetia - Empyreal Paradox
    [291] = 85626, --Reisenjima

};


local function findDat(datId)
    for i = 1,10 do
        local vTablePath;
        if i == 1 then
            vTablePath = string.format('%sVTABLE.DAT', clientPath);
        else
            vTablePath = string.format('%sROM%u\\VTABLE%u.DAT', clientPath, i, i);
        end
        local vTable = io.open(vTablePath, 'rb');
        if vTable then
            vTable:seek('set', datId);
            local temp = struct.unpack('B', vTable:read(1));
            if temp == i then
                local fTablePath;
                if i == 1 then
                    fTablePath = string.format('%sFTABLE.DAT', clientPath);
                else
                    fTablePath = string.format('%sROM%u\\FTABLE%u.DAT', clientPath, i, i);
                end
                local fTable = io.open(fTablePath, 'rb');

                if fTable then
                    fTable:seek('set', datId * 2);
                    local data = fTable:read(2);
                    local path = struct.unpack('H', data);
                    if i == 1 then
                        return string.format('%sROM\\%u\\%u.DAT', pivotPath, bit.rshift(path, 7), bit.band(path, 0x7F));
                    else
                        return string.format('%sROM%u\\%u\\%u.DAT', pivotPath, i, bit.rshift(path, 7), bit.band(path, 0x7F));                        
                    end
                end
            end
        end
    end
    return nil;
end

local function readDat(path, zoneId)
    local dat = io.open(path, 'rb');
    if dat then
        local datSize = struct.unpack('L', dat:read(4)) - 0x10000000;
        local firstEntry = bit.bxor(struct.unpack('L', dat:read(4)), 0x80808080);
        local buffer = ffi.new("uint8_t[?]", datSize)
        -- Read whole file and store it as a C buffer.
        dat:seek('set', 0);
        ffi.copy(buffer, dat:read('a'), datSize)
        dat:close()

        for i = 0,datSize - 1 do
            buffer[i] = bit.bxor(buffer[i], 0x80);
        end

        local data = ffi.string(buffer, datSize);
        local position = 5;
        local offsets = T{};
        while position < firstEntry do
            offsets:append(struct.unpack('L', data, position));
            position = position + 4;
        end
        offsets:append(datSize - 4);
        
        local outPath = string.format(outputPath, AshitaCore:GetResourceManager():GetString("zones.names", zoneId));
        local out = io.open(outPath, 'w');
        local messages = T{};
        for i = 1, #offsets - 1 do
            local startPosition = offsets[i];
            local length = offsets[i + 1] - offsets[i];
            messages[i] = struct.unpack(string.format('c%u', length), data, startPosition + 5);
            out:write((i - 1) .. ': ' .. messages[i] .. '\n\n');
        end
        out:close();
        return true;
    end
    return false;
end

local function ParseDat(targetZone)
    local zoneDatId = zoneDats[targetZone];
    if zoneDatId then
        local datPath = findDat(zoneDats[targetZone]);
        if datPath then
            if readDat(datPath, targetZone) then
                print('Dat parsing complete.');
            else
                print('Dat could not be opened.');
            end
        else
            print('Dat could not be located in vtable.');
        end
    else
        print('Dat ID was not specified.');
    end
end


ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0) then
        return;
    end
    args[1] = string.lower(args[1]);
    if (args[1] ~= '/parsedat') then
        return;
    end

    e.blocked = true;
    for i = 1,299 do
        ParseDat(i);
    end
end);