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
        size = vector3(100,100,100),
        somedata = "test"..i
    })
end

for i=1,1000 do 
    local x = math.random(0,8000)
    local y = math.random(0,8000)
    local z = math.random(0,8000)
    tree:insert_circle({
        center = vector3(x,y,z),
        radius = 1000,
        somedata = "asd"..i
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

print("point by circle",#tree:query_points_by_circle({
    center = vector3(222.0,4000.0,30.0),
    radius = 1000
}))

print("boxes by rectangle",#tree:query_boxes_by_rectangle({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(400.0,400.0,400.0)
}))

print("boxes by point",#tree:query_boxes_by_point(vector3(1.0,1.0,30.0)))
local boxes = tree:query_boxes_by_point(vector3(1.0,1.0,30.0))
for i,v in pairs(boxes) do 
    --print(v.somedata)
end 

print("boxes by circle",#tree:query_boxes_by_circle({
    center = vector3(222.0,4000.0,30.0),
    radius = 1000
}))


print("circles by rectangle",#tree:query_circles_by_rectangle({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(400.0,400.0,400.0)
}))

print("circles by point",#tree:query_circles_by_point(vector3(1.0,1.0,30.0)))

print("circles by circle",#tree:query_circles_by_circle({
    center = vector3(4000.0,4000.0,30.0),
    radius = 555
}))
```
