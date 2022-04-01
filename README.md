# QuadTree
Quadtree utilities for FiveM

## Installation
Set it as a dependency in you fxmanifest.lua
```
client_script '@quadtree/quadtree.lua'
```

## Usage

```


local tree = QuadTree.new({
    center = vector3(4000.0,4000.0,30.0),
    size = vector3(8000.0,8000.0,8000.0)
}, 10)

for i=1,1000 do 
    local x = math.random(0,8000)
    local y = math.random(0,8000)
    local z = math.random(0,8000)
    tree:insert_point(vector3(x,y,z))
end
for i=1,1000 do 
    local x = math.random(0,8000)
    local y = math.random(0,8000)
    local z = math.random(0,8000)
    tree:insert_object("circle?",{
        center = vector3(x,y,z),
        size = vector3(1.0,1.0,1.0),
        whatisthat = "circle"..(i)
    })
end

print(tree)
print(tree.topleft)
print(tree.topright)
print(tree.bottomleft)
print(tree.bottomright)
print(tree.topleft.topleft)
print(tree.topleft.topright)
print(tree.topright.topleft)
print(tree.topright.topright)
print(tree.topleft.topleft.topleft)
print(tree.topleft.topleft.topleft.topleft)

print("point by rectangle",#tree:query_points_by_rectangle({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(400.0,400.0,400.0)
}))

print("point by point",#tree:query_points_by_point(vector3(1.0,1.0,30.0)))

print("point by circle",#tree:query_points_by_point(vector3(1.0,1.0,30.0),100000))

print("object by point",#tree:query_objects_by_point("circle?",vector3(1.0,1.0,30.0)))

print("object by rectangle",#tree:query_objects_by_rectangle("circle?",{
    center = vector3(222.0,4000.0,30.0),
    size = vector3(400.0,400.0,400.0)
}))




```

Other Example relative Zones query
```

local mapMinX, mapMinY, mapMaxX, mapMaxY = -3700, -4400, 4500, 8000
local mapMinZ, mapMaxZ = 8000, 8000

local mapCenter = vector3(mapMinX + (mapMaxX - mapMinX) / 2, mapMinY + (mapMaxY - mapMinY) / 2, mapMinZ + (mapMaxZ - mapMinZ) / 2)

local zonetree =  QuadTree.new({
    center = mapCenter,
    game_center = vector3(mapMinX + (mapMaxX - mapMinX) / 2, mapMinY + (mapMaxY - mapMinY) / 2, mapMinZ),
    size = vector3(mapMaxX - mapMinX, mapMaxY - mapMinY, mapMaxZ - mapMinZ)
}, 4)

CreateThread(function()
    --zonetree:Debug()
end)
InsertMinMaxIntoZoneTree = function(zone)
    local center = zone.get_coords()
    local size = zone.get_size()
    zonetree:insert_object("zone",{
        center = center,
        size = size,
        zone = zone
    })
end

GetNearZonesQuery = function(point)
    return zonetree:query_objects_by_point("zone",point)
end 

IsPointInZonesQuery = function(point,zone)
    local found = false 
    local nearzones = GetNearZonesQuery(point)
    for i=1,#nearzones do
        if nearzones[i].zone == zone then 
            found = true 
            break
        end 
    end
    return found
end


```

## test example by new_banking
```
local useQuadtree = true 
--================================================================================================
--==                                VARIABLES - DO NOT EDIT                                     ==
--================================================================================================
ESX                         = nil
inMenu                      = true
local showblips = true
local atbank = false
local bankMenu = true
local banks = {
  {name="Bank", id=108, x=150.266, y=-1040.203, z=29.374},
  {name="Bank", id=108, x=-1212.980, y=-330.841, z=37.787},
  {name="Bank", id=108, x=-2962.582, y=482.627, z=15.703},
  {name="Bank", id=108, x=-112.202, y=6469.295, z=31.626},
  {name="Bank", id=108, x=314.187, y=-278.621, z=54.170},
  {name="Bank", id=108, x=-351.534, y=-49.529, z=49.042},
  {name="Bank", id=108, x=241.727, y=220.706, z=106.286},
  {name="Bank", id=108, x=1175.0643310547, y=2706.6435546875, z=38.094036102295}
}	

local atms = {
  {name="ATM", id=277, x=-386.733, y=6045.953, z=31.501},
  {name="ATM", id=277, x=-284.037, y=6224.385, z=31.187},
  {name="ATM", id=277, x=-284.037, y=6224.385, z=31.187},
  {name="ATM", id=277, x=-135.165, y=6365.738, z=31.101},
  {name="ATM", id=277, x=-110.753, y=6467.703, z=31.784},
  {name="ATM", id=277, x=-94.9690, y=6455.301, z=31.784},
  {name="ATM", id=277, x=155.4300, y=6641.991, z=31.784},
  {name="ATM", id=277, x=174.6720, y=6637.218, z=31.784},
  {name="ATM", id=277, x=1703.138, y=6426.783, z=32.730},
  {name="ATM", id=277, x=1735.114, y=6411.035, z=35.164},
  {name="ATM", id=277, x=1702.842, y=4933.593, z=42.051},
  {name="ATM", id=277, x=1967.333, y=3744.293, z=32.272},
  {name="ATM", id=277, x=1821.917, y=3683.483, z=34.244},
  {name="ATM", id=277, x=1174.532, y=2705.278, z=38.027},
  {name="ATM", id=277, x=540.0420, y=2671.007, z=42.177},
  {name="ATM", id=277, x=2564.399, y=2585.100, z=38.016},
  {name="ATM", id=277, x=2558.683, y=349.6010, z=108.050},
  {name="ATM", id=277, x=2558.051, y=389.4817, z=108.660},
  {name="ATM", id=277, x=1077.692, y=-775.796, z=58.218},
  {name="ATM", id=277, x=1139.018, y=-469.886, z=66.789},
  {name="ATM", id=277, x=1168.975, y=-457.241, z=66.641},
  {name="ATM", id=277, x=1153.884, y=-326.540, z=69.245},
  {name="ATM", id=277, x=381.2827, y=323.2518, z=103.270},
  {name="ATM", id=277, x=236.4638, y=217.4718, z=106.840},
  {name="ATM", id=277, x=265.0043, y=212.1717, z=106.780},
  {name="ATM", id=277, x=285.2029, y=143.5690, z=104.970},
  {name="ATM", id=277, x=157.7698, y=233.5450, z=106.450},
  {name="ATM", id=277, x=-164.568, y=233.5066, z=94.919},
  {name="ATM", id=277, x=-1827.04, y=785.5159, z=138.020},
  {name="ATM", id=277, x=-1409.39, y=-99.2603, z=52.473},
  {name="ATM", id=277, x=-1205.35, y=-325.579, z=37.870},
  {name="ATM", id=277, x=-1215.64, y=-332.231, z=37.881},
  {name="ATM", id=277, x=-2072.41, y=-316.959, z=13.345},
  {name="ATM", id=277, x=-2975.72, y=379.7737, z=14.992},
  {name="ATM", id=277, x=-2962.60, y=482.1914, z=15.762},
  {name="ATM", id=277, x=-2955.70, y=488.7218, z=15.486},
  {name="ATM", id=277, x=-3044.22, y=595.2429, z=7.595},
  {name="ATM", id=277, x=-3144.13, y=1127.415, z=20.868},
  {name="ATM", id=277, x=-3241.10, y=996.6881, z=12.500},
  {name="ATM", id=277, x=-3241.11, y=1009.152, z=12.877},
  {name="ATM", id=277, x=-1305.40, y=-706.240, z=25.352},
  {name="ATM", id=277, x=-538.225, y=-854.423, z=29.234},
  {name="ATM", id=277, x=-711.156, y=-818.958, z=23.768},
  {name="ATM", id=277, x=-717.614, y=-915.880, z=19.268},
  {name="ATM", id=277, x=-526.566, y=-1222.90, z=18.434},
  {name="ATM", id=277, x=-256.831, y=-719.646, z=33.444},
  {name="ATM", id=277, x=-203.548, y=-861.588, z=30.205},
  {name="ATM", id=277, x=112.4102, y=-776.162, z=31.427},
  {name="ATM", id=277, x=112.9290, y=-818.710, z=31.386},
  {name="ATM", id=277, x=119.9000, y=-883.826, z=31.191},
  {name="ATM", id=277, x=149.4551, y=-1038.95, z=29.366},
  {name="ATM", id=277, x=-846.304, y=-340.402, z=38.687},
  {name="ATM", id=277, x=-1204.35, y=-324.391, z=37.877},
  {name="ATM", id=277, x=-1216.27, y=-331.461, z=37.773},
  {name="ATM", id=277, x=-56.1935, y=-1752.53, z=29.452},
  {name="ATM", id=277, x=-261.692, y=-2012.64, z=30.121},
  {name="ATM", id=277, x=-273.001, y=-2025.60, z=30.197},
  {name="ATM", id=277, x=314.187, y=-278.621, z=54.170},
  {name="ATM", id=277, x=-351.534, y=-49.529, z=49.042},
  {name="ATM", id=277, x=24.589, y=-946.056, z=29.357},
  {name="ATM", id=277, x=-254.112, y=-692.483, z=33.616},
  {name="ATM", id=277, x=-1570.197, y=-546.651, z=34.955},
  {name="ATM", id=277, x=-1415.909, y=-211.825, z=46.500},
  {name="ATM", id=277, x=-1430.112, y=-211.014, z=46.500},
  {name="ATM", id=277, x=33.232, y=-1347.849, z=29.497},
  {name="ATM", id=277, x=129.216, y=-1292.347, z=29.269},
  {name="ATM", id=277, x=287.645, y=-1282.646, z=29.659},
  {name="ATM", id=277, x=289.012, y=-1256.545, z=29.440},
  {name="ATM", id=277, x=295.839, y=-895.640, z=29.217},
  {name="ATM", id=277, x=1686.753, y=4815.809, z=42.008},
  {name="ATM", id=277, x=-302.408, y=-829.945, z=32.417},
  {name="ATM", id=277, x=5.134, y=-919.949, z=29.557},

}
local testatms = {}
local testbanks = {}
local mapMinX, mapMinY, mapMaxX, mapMaxY = -3700, -4400, 4500, 8000  --found from polyzone resource
local mapCenter = vector3(mapMinX + (mapMaxX - mapMinX) / 2, mapMinY + (mapMaxY - mapMinY) / 2, 0)
local mapSize = vector3(mapMaxX - mapMinX, mapMaxY - mapMinY, 0)
local newbanktree =  QuadTree.new({
    center = mapCenter,
    size = mapSize
}, 2)
local newatmtree =  QuadTree.new({
  center = mapCenter,
  size = mapSize
}, 2)

for i,v in pairs(atms) do 
  newatmtree:insert_point(v)
  table.insert(testatms, v)
end 

for i,v in pairs(banks) do 
  newbanktree:insert_point(v)
  table.insert(testbanks, v)
end 

for i=1,100 do --test add 100 x N atms into the map
    for i,v in pairs(atms) do 
  newatmtree:insert_point(v)
  table.insert(testatms, v)
end 

for i,v in pairs(banks) do 
  newbanktree:insert_point(v)
  table.insert(testbanks, v)
end 
end 

CreateThread(function()
  --newatmtree:Debug(50.0)
  --newbanktree:Debug(50.0)
end)

GetNearBanksQuery = function(point)
    return newbanktree:query_points_by_point(point,3.0)
end 

GetNearAtmsQuery = function(point)
  return newatmtree:query_points_by_point(point,3.0)
end 


--===============================================
--==             Core Threading                ==
--===============================================
Citizen.CreateThread(function()
  while true do
    Wait(0)
    
	if nearBank()  then
			DisplayHelpText("Press ~INPUT_PICKUP~ to access the bank ~b~")
    
		if IsControlJustPressed(1, 38) then
			print("open")
		end
	end
  if nearATM()  then
    DisplayHelpText("Press ~INPUT_PICKUP~ to access the atm ~b~")
  
  if IsControlJustPressed(1, 38) then
    print("open")
  end
end
        
    if IsControlJustPressed(1, 322) then
      print("close")
    end
	end
  end)
--===============================================
--==            Capture Bank Distance          ==
--===============================================
--quadtree
if useQuadtree then 
function nearBank()
	local player = PlayerPedId()
	local playerloc = GetEntityCoords(player, 0)
  local preparedbanks = GetNearBanksQuery(playerloc)
  return #preparedbanks > 0
end

function nearATM()
	local player = PlayerPedId()
	local playerloc = GetEntityCoords(player, 0)
  local preparedatms = GetNearAtmsQuery(playerloc)
  return #preparedatms > 0
end
else 
--without quadtree
function nearBank()
	local player = PlayerPedId()
	local playerloc = GetEntityCoords(player, 0)
  --local preparedbanks = GetNearBanksQuery(playerloc)
  for _, search in pairs(testbanks) do
		local distance = GetDistanceBetweenCoords(search.x, search.y, search.z, playerloc['x'], playerloc['y'], playerloc['z'], true)
		
		if distance <= 3 then
			return true
		end
	end
end

function nearATM()
	local player = PlayerPedId()
	local playerloc = GetEntityCoords(player, 0)
  --local preparedatms = GetNearAtmsQuery(playerloc)
  for _, search in pairs(testatms) do
		local distance = GetDistanceBetweenCoords(search.x, search.y, search.z, playerloc['x'], playerloc['y'], playerloc['z'], true)
		
		if distance <= 3 then
			return true
		end
	end
end
end
function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end
```