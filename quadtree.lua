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
        local rectanglecenter  
        local rectanglecenterx 
        local rectanglecentery 
        if rectangle.getcenter then 
            rectanglecenter = rectangle.getcenter()
            rectanglecenterx , rectanglecentery = rectanglecenter.x, rectanglecenter.y
        else 
            rectanglecenter = rectangle.center
            rectanglecenterx , rectanglecentery = rectanglecenter.x, rectanglecenter.y
        end
        if rectangle.getminmax then 
            local rectanglemin,rectanglemax = rectangle.getminmax()
            local pointAx = pointA.x
            local pointAy = pointA.y
            local rectangleminx = rectanglemin.x
            local rectangleminy = rectanglemin.y
            local rectanglemaxx = rectanglemax.x
            local rectanglemaxy = rectanglemax.y
            
            return pointAx >= rectangleminx - radius and pointAx <= rectanglemaxx + radius and pointAy >= rectangleminy - radius and pointAy <= rectanglemaxy + radius
        end 
        if rectangle.min == nil then 
            local rectanglesize = rectangle.size
            local rectanglehalfwidth =  rectanglesize.x/2
            local rectanglehalfheight = rectanglesize.y/2
            local pointAx = pointA.x
            local pointAy = pointA.y
            --return pointA.x >= rectangle.center.x - rectangle.size.x/2 - radius and pointA.x <= rectangle.center.x + rectangle.size.x/2 + radius and pointA.y >= rectangle.center.y - rectangle.size.y/2 - radius and pointA.y <= rectangle.center.y + rectangle.size.y/2 + radius
            return pointAx >= rectanglecenterx - rectanglehalfwidth - radius and pointAx <= rectanglecenterx + rectanglehalfwidth + radius and pointAy >= rectanglecentery - rectanglehalfheight - radius and pointAy <= rectanglecentery + rectanglehalfheight + radius
        elseif rectangle.max then 
            local pointAx = pointA.x
            local pointAy = pointA.y
            local rectangleminx = rectangle.min.x
            local rectangleminy = rectangle.min.y
            local rectanglemaxx = rectangle.max.x
            local rectanglemaxy = rectangle.max.y
            return pointAx >= rectangleminx - radius and pointAx <= rectanglemaxx + radius and pointAy >= rectangleminy - radius and pointAy <= rectanglemaxy + radius
        end
    end,
    
}


function QuadTree.new(boundary, capacity)
    local o = {
        center   =  boundary.center,
        size = boundary.size,
        capacity = capacity or 4,
        points = {},
        isdivided = false,
        isinquery = false,
    }
    return setmetatable(
        o, {
        __index = QuadTree,
        __tostring = function(self)
            return "QuadTree: center: "..self.center.x.." "..self.center.y..
            " width: "..self.size.x.." height: "..self.size.y..
            " capacity: "..self.capacity.." points: "..#self.points..
              " isdivided: "..tostring(self.isdivided)
            
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

function QuadTree:query_points_by_rectangle(rectrange)
    local found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, point in ipairs(self.points) do
        if Contains.pointtorectangle(point, rectrange) then
            table.insert(found, point)
        end
    end
    if self.isdivided then
        table.insert(found,self.topright:query_points_by_rectangle(rectrange))
        table.insert(found,self.bottomright:query_points_by_rectangle(rectrange))
        table.insert(found,self.bottomleft:query_points_by_rectangle(rectrange))
        table.insert(found,self.topleft:query_points_by_rectangle(rectrange))
    end
    return found
end


function QuadTree:query_points_by_point(point, radius)
    local found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, point_ in ipairs(self.points) do
        if Contains.pointtopoint(point_, point, radius) then
            table.insert(found, point_)
        end
    end
    if self.isdivided then
        table.insert(self.topright:query_points_by_point(point, radius))
        table.insert(self.bottomright:query_points_by_point(point, radius))
        table.insert(self.bottomleft:query_points_by_point(point, radius))
        table.insert(self.topleft:query_points_by_point(point, radius))
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

