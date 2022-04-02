local setmetatable = setmetatable
local DrawLine = DrawLine
local GetEntityCoords = GetEntityCoords
local Wait = Wait
local CreateThread = CreateThread
local table = table
local ipairs = ipairs
local math = math
local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords
local vector3 = vector3
local vector2 = vector2

QuadTree = {}
local Contains = {
    pointtopoint = function(pointA,pointB,radius)
        local radius = radius or 0
        return #(vector2(pointA.x,pointA.y) - vector2(pointB.x,pointB.y)) <= radius
    end,
    pointtorectangle = function(pointA,rectangle,radius)
        local radius = radius or 0
        local rectanglecenter = rectangle.center
        local rectanglecenterx = rectanglecenter.x
        local rectanglecentery = rectanglecenter.y
        local rectanglesize = rectangle.size
        local rectanglehalfwidth =  rectanglesize.x/2
        local rectanglehalfheight = rectanglesize.y/2
        local pointAx = pointA.x
        local pointAy = pointA.y
        --return pointA.x >= rectangle.center.x - rectangle.size.x/2 - radius and pointA.x <= rectangle.center.x + rectangle.size.x/2 + radius and pointA.y >= rectangle.center.y - rectangle.size.y/2 - radius and pointA.y <= rectangle.center.y + rectangle.size.y/2 + radius
        return pointAx >= rectanglecenterx - rectanglehalfwidth - radius and pointAx <= rectanglecenterx + rectanglehalfwidth + radius and pointAy >= rectanglecentery - rectanglehalfheight - radius and pointAy <= rectanglecentery + rectanglehalfheight + radius
    end,
    rectangletorectangle = function(rectangleA,rectangleB,radius)
        local radius = radius or 0
        local rectangleAcenter = rectangleA.center
        local rectangleAcenterx = rectangleAcenter.x
        local rectangleAcentery = rectangleAcenter.y
        local rectangleAsize = rectangleA.size
        local rectangleAhalfwidth =  rectangleAsize.x/2
        local rectangleAhalfheight = rectangleAsize.y/2
        local rectangleBcenter = rectangleB.center
        local rectangleBcenterx = rectangleBcenter.x
        local rectangleBcentery = rectangleBcenter.y
        local rectangleBsize = rectangleB.size
        local rectangleBhalfwidth =  rectangleBsize.x/2
        local rectangleBhalfheight = rectangleBsize.y/2
        --return rectangleA.center.x - rectangleA.size.x/2 - radius <= rectangleB.center.x + rectangleB.size.x/2 + radius and rectangleA.center.x + rectangleA.size.x/2 + radius >= rectangleB.center.x - rectangleB.size.x/2 - radius and rectangleA.center.y - rectangleA.size.y/2 - radius <= rectangleB.center.y + rectangleB.size.y/2 + radius and rectangleA.center.y + rectangleA.size.y/2 + radius >= rectangleB.center.y - rectangleB.size.y/2 - radius
        return rectangleAcenterx - rectangleAhalfwidth - radius <= rectangleBcenterx + rectangleBhalfwidth + radius and rectangleAcenterx + rectangleAhalfwidth + radius >= rectangleBcenterx - rectangleBhalfwidth - radius and rectangleAcentery - rectangleAhalfheight - radius <= rectangleBcentery + rectangleBhalfheight + radius and rectangleAcentery + rectangleAhalfheight + radius >= rectangleBcentery - rectangleBhalfheight - radius
    end,
}


function QuadTree.new(boundary, capacity)
    local o = {
        center   =  boundary.center,
        size = boundary.size,
        capacity = capacity or 4,
        points = {},
        objects = {},
        isdivided = false,
        isinquery = false,
    }
    setmetatable(o.objects,{__tostring = function(t) 
        local r = ""
        for i,v in pairs(t) do 
            r = r .. i.."("..#v..")" .. " "
        end 
        return r
    end})
    return setmetatable(
        o, {
        __index = QuadTree,
        __tostring = function(self)
            return "QuadTree: center: "..self.center.x.." "..self.center.y..
            " width: "..self.size.x.." height: "..self.size.y..
            " capacity: "..self.capacity.." points: "..#self.points..
              " isdivided: "..tostring(self.isdivided).."\nobjects: "..tostring(self.objects)
            
        end
    })
end

function QuadTree:inner_subdivide()
    local parentcenter = self.center
    local parentsize = self.size
    local parentwidth =  parentsize.x
    local parentheight = parentsize.y
    local parentcenterx = parentcenter.x
    local parentcentery = parentcenter.y
    local childwidth = parentwidth/2
    local childheight = parentheight/2
    local childhalfwidth = childwidth/2
    local childhalfheight = childheight/2
    
    local toleftX = parentcenterx - childhalfwidth
    local torightX = parentcenterx + childhalfwidth
    local toupY = parentcentery - childhalfheight
    local todownY = parentcentery + childhalfheight

    local childsize = vector2(childwidth, childheight)
    local parentcapacity = self.capacity

    --create new quadtrees in 4 sub-regions
    self.topright = QuadTree.new({
        center = vector2(torightX, toupY),
        size = childsize
    }, parentcapacity)
    self.bottomright = QuadTree.new({
        center = vector2(torightX, todownY),
        size = childsize
    }, parentcapacity)
    self.bottomleft = QuadTree.new({
        center = vector2(toleftX, todownY),
        size = childsize
    }, parentcapacity)
    self.topleft = QuadTree.new({
        center = vector2(toleftX, toupY),
        size = childsize
    }, parentcapacity)

    self.isdivided = true
        
end

function QuadTree:inner_intersects(rectangle)
    local rectcenter = rectangle.center
    local rectcenterx = rectcenter.x
    local rectcentery = rectcenter.y
    local selfcenter = self.center
    local selfcenterx = selfcenter.x
    local selfcentery = selfcenter.y
    local recthalfsize = rectangle.size/2
    local selfhalfsize = self.size/2
    local recthalfsizex = recthalfsize.x
    local recthalfsizey = recthalfsize.y
    local selfhalfsizex = selfhalfsize.x
    local selfhalfsizey = selfhalfsize.y
    local isrectanglein = 
        rectcenterx - recthalfsizex <= selfcenterx + selfhalfsizex and
        rectcenterx + recthalfsizex >= selfcenterx - selfhalfsizex and
        rectcentery - recthalfsizey <= selfcentery + selfhalfsizey and
        rectcentery + recthalfsizey >= selfcentery - selfhalfsizey
    return isrectanglein
end

function QuadTree:inner_point_contains (point, radius)
    local radius = radius or 0.0
    local selfcenter = self.center
    local selfcenterx = selfcenter.x
    local selfcentery = selfcenter.y
    local selfhalfsize = self.size/2
    local pointx = point.x
    local pointy = point.y
    --return point.x + radius >= self.center.x - self.size.x/2 and point.x - radius <= self.center.x + self.size.x/2 and point.y + radius >= self.center.y - self.size.y/2 and point.y - radius <= self.center.y + self.size.y/2
    return pointx + radius >= selfcenterx - selfhalfsize.x and pointx - radius <= selfcenterx + selfhalfsize.x and pointy + radius >= selfcentery - selfhalfsize.y and pointy - radius <= selfcentery + selfhalfsize.y
end

function QuadTree:insert_point(point)
    if not self:inner_point_contains(point) then
        return false
    end
    if #self.points < self.capacity then
        table.insert(self.points, point)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_point(point) then
            return true
        elseif self.bottomright:insert_point(point) then
            return true
        elseif self.bottomleft:insert_point(point) then
            return true
        elseif self.topleft:insert_point(point) then
            return true
        end
    end
end

function QuadTree:remove_point (point)
    if not self:inner_point_contains(point) then
        return false
    end
    if #self.points > 0 then
        for i, v in ipairs(self.points) do
            if v == point then
                table.remove(self.points, i)
                return true
            end
        end
    end
    if self.isdivided then
        if self.topright:remove_point(point) then
            return true
        elseif self.bottomright:remove_point(point) then
            return true
        elseif self.bottomleft:remove_point(point) then
            return true
        elseif self.topleft:remove_point(point) then
            return true
        end
    end
end

function QuadTree:update_point(point)
    self:remove_point(point)
    self:insert_point(point)
end

function QuadTree:query_points_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, point in ipairs(self.points) do
        if Contains.pointtorectangle(point, rectrange) then
            table.insert(found, point)
        end
    end
    if self.isdivided then
        self.topright:query_points_by_rectangle(rectrange, found)
        self.bottomright:query_points_by_rectangle(rectrange, found)
        self.bottomleft:query_points_by_rectangle(rectrange, found)
        self.topleft:query_points_by_rectangle(rectrange, found)
    end
    return found
end


function QuadTree:query_points_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, point_ in ipairs(self.points) do
        if Contains.pointtopoint(point_, point, radius) then
            table.insert(found, point_)
        end
    end
    if self.isdivided then
        self.topright:query_points_by_point(point, radius, found)
        self.bottomright:query_points_by_point(point, radius, found)
        self.bottomleft:query_points_by_point(point, radius, found)
        self.topleft:query_points_by_point(point, radius, found)
    end
    return found
end

function QuadTree:inner_object_contains(object)
    local center = object.center 
    local size = object.size
    local objectcenterx = center.x
    local objectcentery = center.y
    local objecthalfsizex = size.x/2
    local objecthalfsizey = size.y/2
    local selfcenter = self.center
    local selfsize = self.size
    local selfcenterx = selfcenter.x
    local selfcentery = selfcenter.y
    local selfhalfsizex = selfsize.x/2
    local selfhalfsizey = selfsize.y/2

    --return center.x - size.x/2 >= self.center.x - self.size.x/2 and center.x + size.x/2 <= self.center.x + self.size.x/2 and center.y - size.y/2 >= self.center.y - self.size.y/2 and center.y + size.y/2 <= self.center.y + self.size.y/2
    return objectcenterx - objecthalfsizex <= selfcenterx + selfhalfsizex and
        objectcenterx + objecthalfsizex >= selfcenterx - selfhalfsizex and
        objectcentery - objecthalfsizey <= selfcentery + selfhalfsizey and
        objectcentery + objecthalfsizey >= selfcentery - selfhalfsizey
end

function QuadTree:insert_object(catagary_name,object)
    if not self:inner_object_contains(object) then
        return false
    end
    if not self.objects[catagary_name] then
        self.objects[catagary_name] = {}
    end
    if #self.objects[catagary_name] < self.capacity then
        table.insert(self.objects[catagary_name], object)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_object(catagary_name,object) then
            return true
        elseif self.bottomright:insert_object(catagary_name,object) then
            return true
        elseif self.bottomleft:insert_object(catagary_name,object) then
            return true
        elseif self.topleft:insert_object(catagary_name,object) then
            return true
        end
    end
end

function QuadTree:remove_object(catagary_name,object)
    if not self:inner_object_contains(object) then
        return false
    end
    if self.objects[catagary_name] then
        for i, v in ipairs(self.objects[catagary_name]) do
            if v == object then
                table.remove(self.objects[catagary_name], i)
                return true
            end
        end
    else 
        return false
    end
    if self.isdivided then
        if self.topright:remove_object(catagary_name,object) then
            return true
        elseif self.bottomright:remove_object(catagary_name,object) then
            return true
        elseif self.bottomleft:remove_object(catagary_name,object) then
            return true
        elseif self.topleft:remove_object(catagary_name,object) then
            return true
        end
    end
end

function QuadTree:update_object(catagary_name,object)
    self:remove_object(catagary_name,object)
    self:insert_object(catagary_name,object)
end

function QuadTree:query_objects_by_rectangle(catagary_name,rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    if self.objects[catagary_name] then
        for i, object in ipairs(self.objects[catagary_name]) do
            if Contains.rectangletorectangle(object, rectrange) then
                table.insert(found, object)
            end
        end
    else 
        return found
    end
    if self.isdivided then
        self.topright:query_objects_by_rectangle(catagary_name,rectrange, found)
        self.bottomright:query_objects_by_rectangle(catagary_name,rectrange, found)
        self.bottomleft:query_objects_by_rectangle(catagary_name,rectrange, found)
        self.topleft:query_objects_by_rectangle(catagary_name,rectrange, found)
    end
    return found
end

function QuadTree:query_objects_by_point(catagary_name, point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    if self.objects[catagary_name] then
        for i, object in ipairs(self.objects[catagary_name]) do
            if Contains.pointtorectangle(point, object, radius) then
                table.insert(found, object)
            end
        end
    else
        return found
    end
    if self.isdivided then
        self.topright:query_objects_by_point(catagary_name,point, radius, found)
        self.bottomright:query_objects_by_point(catagary_name,point, radius, found)
        self.bottomleft:query_objects_by_point(catagary_name,point, radius, found)
        self.topleft:query_objects_by_point(catagary_name,point, radius, found)
    end
    return found
end


function QuadTree:clear_points()
    self.points = {}
    if self.isdivided then
        self.topright:clear_points()
        self.bottomright:clear_points()
        self.bottomleft:clear_points()
        self.topleft:clear_points()
    end
end

function QuadTree:clear_objects(catagary_name)
    self.objects[catagary_name] = {}
    if self.isdivided then
        self.topright:clear_object(catagary_name)
        self.bottomright:clear_object(catagary_name)
        self.bottomleft:clear_object(catagary_name)
        self.topleft:clear_object(catagary_name)
    end
end

function QuadTree:clear_all()
    self.points = {}
    self.objects = {}
    if self.isdivided then
        self.topright:clear_all()
        self.bottomright:clear_all()
        self.bottomleft:clear_all()
        self.topleft:clear_all()
    end
end




function QuadTree:DrawGrids(freezeZ)
    local r,g,b,a = 255,255,255,255
    if self.isinquery then
        r,g,b,a = 0,255,0,255
    end
    local drawz = freezeZ or (GetEntityCoords(GetPlayerPed(-1)).z + 1.0)
        DrawLine(self.center.x-self.size.x/2,self.center.y-self.size.y/2,drawz,self.center.x+self.size.x/2,self.center.y-self.size.y/2,drawz,r,g,b,a)
        DrawLine(self.center.x+self.size.x/2,self.center.y-self.size.y/2,drawz,self.center.x+self.size.x/2,self.center.y+self.size.y/2,drawz,r,g,b,a)

        DrawLine(self.center.x+self.size.x/2,self.center.y+self.size.y/2,drawz,self.center.x-self.size.x/2,self.center.y+self.size.y/2,drawz,r,g,b,a)
        DrawLine(self.center.x-self.size.x/2,self.center.y+self.size.y/2,drawz,self.center.x-self.size.x/2,self.center.y-self.size.y/2,drawz,r,g,b,a)

        DrawLine(self.center.x-self.size.x/2,self.center.y,drawz,self.center.x+self.size.x/2,self.center.y,drawz,r,g,b,a)
        DrawLine(self.center.x,self.center.y-self.size.y/2,drawz,self.center.x,self.center.y+self.size.y/2,drawz,r,g,b,a)
        
        if self.points[1] then
            for i, point in ipairs(self.points) do
                DrawLine(point.x,point.y,drawz,point.x,point.y,drawz+2^10,r,g,255,a)
            end
        end
        for i,v in pairs(self.objects) do 
            if v[1] then
                for i, obj in ipairs(v) do
                    local center = obj.center 
                    DrawLine(center.x,center.y,drawz,center.x,center.y,drawz+2^10,255,0,255,255)
                end
            end
        end
    if self.isdivided then
        self.topright:DrawGrids(freezeZ)
        self.bottomright:DrawGrids(freezeZ)
        self.bottomleft:DrawGrids(freezeZ)
        self.topleft:DrawGrids(freezeZ)
    end
end

function QuadTree:Debug(freezeZ)
    CreateThread(function()
        while true do
            self:DrawGrids(freezeZ)
            Wait(0)
        end
    end)
end

