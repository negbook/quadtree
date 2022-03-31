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
    tree:insert_box({
        center = vector3(x,y,z),
        size = vector3(100,100,100)
    })
end

for i=1,1000 do 
    local x = math.random(0,8000)
    local y = math.random(0,8000)
    local z = math.random(0,8000)
    tree:insert_polygon({
        vector3(x,y,z),
        vector3(x+100,y,z),
        vector3(x+100,y+100,z),
        vector3(x,y+100,z)
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

print("boxes by rectangle",#tree:query_boxes_by_rectangle({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(400.0,400.0,400.0)
}))

print("boxes by point",#tree:query_boxes_by_point(vector3(1.0,1.0,30.0)))

print("polygons by rectangle",#tree:query_polygons_by_rectangle({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(400.0,400.0,400.0)
}))

print("polygons by point",#tree:query_polygons_by_point(vector3(4441.0,4441.0,30.0)))

print("polygons by circle",#tree:query_polygons_by_circle(vector3(4000.0,4000.0,30.0), 500))
```
