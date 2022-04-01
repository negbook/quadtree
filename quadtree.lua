QuadTree = {}
Contains = {
    pointtopoint = function(pointA,pointB,radius)
        local radius = radius or 0
        return #(vector2(pointA.x,pointA.y) - vector2(pointB.x,pointB.y)) <= radius
    end,
    pointtorectangle = function(pointA,rectangle,radius)
        local radius = radius or 0
        local distance = #(vector2(pointA.x,pointA.y) - vector2(rectangle.center.x,rectangle.center.y))
        return distance <= radius and distance <= rectangle.size.x/2 and distance <= rectangle.size.y/2
    end,
    pointtocircle = function(pointA,circle,radius)
        local radius = radius or 0
        local distance = #(vector2(pointA.x,pointA.y) - vector2(circle.center.x,circle.center.y))
        return distance <= radius and distance <= circle.radius
    end,
    rectangletopoint = function(rectangleA,pointA,radius)
        local radius = radius or 0
        return pointA.x >= rectangleA.center.x - rectangleA.size.x/2 - radius and pointA.x <= rectangleA.center.x + rectangleA.size.x/2 + radius and pointA.y >= rectangleA.center.y - rectangleA.size.y/2 - radius and pointA.y <= rectangleA.center.y + rectangleA.size.y/2 + radius
    end,
    rectangletorectangle = function(rectangleA,rectangleB,radius)
        local radius = radius or 0
        return rectangleA.center.x - rectangleA.size.x/2 - radius <= rectangleB.center.x + rectangleB.size.x/2 + radius and rectangleA.center.x + rectangleA.size.x/2 + radius >= rectangleB.center.x - rectangleB.size.x/2 - radius and rectangleA.center.y - rectangleA.size.y/2 - radius <= rectangleB.center.y + rectangleB.size.y/2 + radius and rectangleA.center.y + rectangleA.size.y/2 + radius >= rectangleB.center.y - rectangleB.size.y/2 - radius
    end,
    rectangletocircle = function(rectangle,circle,radius)
        local radius = radius or 0
        return rectangle.center.x - rectangle.size.x/2 - radius <= circle.center.x + circle.radius and rectangle.center.x + rectangle.size.x/2 + radius >= circle.center.x - circle.radius and rectangle.center.y - rectangle.size.y/2 - radius <= circle.center.y + circle.radius and rectangle.center.y + rectangle.size.y/2 + radius >= circle.center.y - circle.radius
    end,
    circletopoint = function(circle,pointA,radius)
        local radius = radius or 0
        local distance = #(vector2(pointA.x,pointA.y) - vector2(circle.center.x,circle.center.y))
        return distance <= radius and distance <= circle.radius
    end,
    circletorectangle = function(circle,rectangle,radius)
        local radius = radius or 0
        return circle.center.x - circle.radius <= rectangle.center.x + rectangle.size.x/2 + radius and circle.center.x + circle.radius >= rectangle.center.x - rectangle.size.x/2 - radius and circle.center.y - circle.radius <= rectangle.center.y + rectangle.size.y/2 + radius and circle.center.y + circle.radius >= rectangle.center.y - rectangle.size.y/2 - radius
    end,
    circletocircle = function(circleA,circleB,radius)
        local radius = radius or 0
        return #(vector2(circleA.center.x,circleA.center.y) - vector2(circleB.center.x,circleB.center.y)) <= circleA.radius + circleB.radius
    end,
    boundingboxtopoint = function(boundingbox,pointA,radius)
        local radius = radius or 0
        return pointA.x >= boundingbox.min.x - radius and pointA.x <= boundingbox.max.x + radius and pointA.y >= boundingbox.min.y - radius and pointA.y <= boundingbox.max.y + radius
    end,
    boundingboxtorectangle = function(boundingbox,rectangle,radius)
        local radius = radius or 0
        return boundingbox.min.x - radius <= rectangle.center.x + rectangle.size.x/2 + radius and boundingbox.max.x + radius >= rectangle.center.x - rectangle.size.x/2 - radius and boundingbox.min.y - radius <= rectangle.center.y + rectangle.size.y/2 + radius and boundingbox.max.y + radius >= rectangle.center.y - rectangle.size.y/2 - radius
    end,
}


function QuadTree.new(boundary, capacity)
    local boundary_left = boundary.center.x - boundary.size.x/2
    local boundary_right = boundary.center.x + boundary.size.x/2
    local boundary_top = boundary.center.y - boundary.size.y/2
    local boundary_bottom = boundary.center.y + boundary.size.y/2
    local boundary_width = boundary.size.x
    local boundary_height = boundary.size.y
    
    
    return setmetatable(
    {
        center   =  vector2(boundary_left + boundary_width/2, boundary_top + boundary_height/2),
        width  =  boundary_width,
        height =  boundary_height,
        size = vector2(boundary_width, boundary_height),
        capacity = capacity or 4,
        points = {},
        circles = {},
        boxes = {},
        boundingboxes = {},
        custom_objects = {},
        isdivided = false,
        isinquery = false,
    }, {
        __index = QuadTree,
        __tostring = function(self)
            return "QuadTree: center: "..self.center.x.." "..self.center.y.." width: "..self.width.." height: "..self.height.." capacity: "..self.capacity.." points: "..#self.points.. " boxes: "..#self.boxes.. " boundingboxes: "..#self.boundingboxes.. " isdivided: "..tostring(self.isdivided)
            
        end
    })
end

function QuadTree:inner_subdivide()
    local parentcenter = self.center
    local parentwidth = self.width
    local parentheight = self.height
    local childwidth = parentwidth/2
    local childheight = parentheight/2

    --create new quadtrees in 4 sub-regions
    self.topright = QuadTree.new({
        center = vector2(parentcenter.x + childwidth/2, parentcenter.y - childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)
    self.bottomright = QuadTree.new({
        center = vector2(parentcenter.x + childwidth/2, parentcenter.y + childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)
    self.bottomleft = QuadTree.new({
        center = vector2(parentcenter.x - childwidth/2, parentcenter.y + childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)
    self.topleft = QuadTree.new({
        center = vector2(parentcenter.x - childwidth/2, parentcenter.y - childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)

    self.isdivided = true
        
end

function QuadTree:inner_intersects(rectrange)
    local rectcenter = rectrange.center
    local rectsize = rectrange.size
    local rectwidth = rectsize.x
    local rectheight = rectsize.y
    return not (rectcenter.x + rectwidth/2 < self.center.x - self.width/2 or rectcenter.x - rectwidth/2 > self.center.x + self.width/2 or rectcenter.y + rectheight/2 < self.center.y - self.height/2 or rectcenter.y - rectheight/2 > self.center.y + self.height/2)
end

function QuadTree:inner_point_contains (point, radius)
    local radius = radius or 0.0
    return point.x >= self.center.x - self.width/2 - radius and point.x <= self.center.x + self.width/2 + radius and point.y >= self.center.y - self.height/2 - radius and point.y <= self.center.y + self.height/2 + radius
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

local GetMinMax = function(b)
   local min = vector2(b.center.x - b.size.x/2, b.center.y - b.size.y/2)
   local max = vector2(b.center.x + b.size.x/2, b.center.y + b.size.y/2)
   return min, max
end

function QuadTree:inner_box_contains(box)
    local min1, max1 = GetMinMax(self)
    local min2, max2 = GetMinMax(box)
    return min1.x <= min2.x and max1.x >= max2.x and min1.y <= min2.y and max1.y >= max2.y
end

function QuadTree:insert_box(box)
    if not self:inner_box_contains(box) then
        return false
    end
    if #self.boxes < self.capacity then
        table.insert(self.boxes, box)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_box(box) then
            return true
        elseif self.bottomright:insert_box(box) then
            return true
        elseif self.bottomleft:insert_box(box) then
            return true
        elseif self.topleft:insert_box(box) then
            return true
        end
    end
end

function QuadTree:remove_box(box)
    if not self:inner_box_contains(box) then
        return false
    end
    if #self.boxes > 0 then
        for i, v in ipairs(self.boxes) do
            if v == box then
                table.remove(self.boxes, i)
                return true
            end
        end
    end
    if self.isdivided then
        if self.topright:remove_box(box) then
            return true
        elseif self.bottomright:remove_box(box) then
            return true
        elseif self.bottomleft:remove_box(box) then
            return true
        elseif self.topleft:remove_box(box) then
            return true
        end
    end
end


function QuadTree:query_boxes_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        if Contains.rectangletorectangle(box, rectrange) then
            table.insert(found, box)
        end
    end
    if self.isdivided then
        self.topright:query_boxes_by_rectangle(rectrange, found)
        self.bottomright:query_boxes_by_rectangle(rectrange, found)
        self.bottomleft:query_boxes_by_rectangle(rectrange, found)
        self.topleft:query_boxes_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_boxes_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        if Contains.rectangletopoint(box, point, radius) then
            table.insert(found, box)
        end
    end
    if self.isdivided then
        self.topright:query_boxes_by_point(point, radius, found)
        self.bottomright:query_boxes_by_point(point, radius, found)
        self.bottomleft:query_boxes_by_point(point, radius, found)
        self.topleft:query_boxes_by_point(point, radius, found)
    end
    return found
end

function QuadTree:inner_circle_contains (circle)
    return self:inner_point_contains(circle.center, circle.radius)
end

function QuadTree:insert_circle(circle)
    if not self:inner_circle_contains(circle) then
        return false
    end
    if #self.circles < self.capacity then
        table.insert(self.circles, circle)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_circle(circle) then
            return true
        elseif self.bottomright:insert_circle(circle) then
            return true
        elseif self.bottomleft:insert_circle(circle) then
            return true
        elseif self.topleft:insert_circle(circle) then
            return true
        end
    end
end

function QuadTree:remove_circle(circle)
    if not self:inner_circle_contains(circle) then
        return false
    end
    if #self.circles > 0 then
        for i, v in ipairs(self.circles) do
            if v == circle then
                table.remove(self.circles, i)
                return true
            end
        end
    end
    if self.isdivided then
        if self.topright:remove_circle(circle) then
            return true
        elseif self.bottomright:remove_circle(circle) then
            return true
        elseif self.bottomleft:remove_circle(circle) then
            return true
        elseif self.topleft:remove_circle(circle) then
            return true
        end
    end
end


function QuadTree:query_circles_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, circle in ipairs(self.circles) do
        if Contains.rectangletocircle(rectrange, circle) then
            table.insert(found, circle)
        end
    end
    if self.isdivided then
        self.topright:query_circles_by_rectangle(rectrange, found)
        self.bottomright:query_circles_by_rectangle(rectrange, found)
        self.bottomleft:query_circles_by_rectangle(rectrange, found)
        self.topleft:query_circles_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_circles_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, circle in ipairs(self.circles) do
        if Contains.circletopoint(circle, point, radius) then
            table.insert(found, circle)
        end
    end
    if self.isdivided then
        self.topright:query_circles_by_point(point, radius, found)
        self.bottomright:query_circles_by_point(point, radius, found)
        self.bottomleft:query_circles_by_point(point, radius, found)
        self.topleft:query_circles_by_point(point, radius, found)
    end
    return found
end

function QuadTree:inner_boundingbox_contains(min,max)
    local min1, max1 = GetMinMax(self)
    local min2, max2 = min,max
    return min1.x <= min2.x and max1.x >= max2.x and min1.y <= min2.y and max1.y >= max2.y
end

function QuadTree:insert_boundingbox(boundingbox)
    local min,max = boundingbox.min,boundingbox.max
    if not self:inner_boundingbox_contains(min,max) then
        return false
    end
    if #self.boundingboxes < self.capacity then
        table.insert(self.boundingboxes, boundingbox)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_boundingbox(boundingbox) then
            return true
        elseif self.bottomright:insert_boundingbox(boundingbox) then
            return true
        elseif self.bottomleft:insert_boundingbox(boundingbox) then
            return true
        elseif self.topleft:insert_boundingbox(boundingbox) then
            return true
        end
    end
end

function QuadTree:remove_boundingbox(boundingbox)
    local min,max = boundingbox.min,boundingbox.max
    if not self:inner_boundingbox_contains(min,max) then
        return false
    end
    if #self.boundingboxes > 0 then
        for i, v in ipairs(self.boundingboxes) do
            if v == boundingbox then
                table.remove(self.boundingboxes, i)
                return true
            end
        end
    end
    if self.isdivided then
        if self.topright:remove_boundingbox(boundingbox) then
            return true
        elseif self.bottomright:remove_boundingbox(boundingbox) then
            return true
        elseif self.bottomleft:remove_boundingbox(boundingbox) then
            return true
        elseif self.topleft:remove_boundingbox(boundingbox) then
            return true
        end
    end
end

function QuadTree:query_boundingboxes_by_rectangle(rectrange, found,min,max)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, boundingbox in ipairs(self.boundingboxes) do
        if Contains.boundingboxtorectangle(boundingbox, rectrange) then
            table.insert(found, boundingbox)
        end
    end
    if self.isdivided then
        self.topright:query_boundingboxes_by_rectangle(rectrange, found,min,max)
        self.bottomright:query_boundingboxes_by_rectangle(rectrange, found,min,max)
        self.bottomleft:query_boundingboxes_by_rectangle(rectrange, found,min,max)
        self.topleft:query_boundingboxes_by_rectangle(rectrange, found,min,max)
    end
    return found
end

function QuadTree:query_boundingboxes_by_point(point, radius, found,min,max)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, boundingbox in ipairs(self.boundingboxes) do
        if Contains.boundingboxtopoint(boundingbox, point, radius) then
            table.insert(found, boundingbox)
        end
    end
    if self.isdivided then
        self.topright:query_boundingboxes_by_point(point, radius, found,min,max)
        self.bottomright:query_boundingboxes_by_point(point, radius, found,min,max)
        self.bottomleft:query_boundingboxes_by_point(point, radius, found,min,max)
        self.topleft:query_boundingboxes_by_point(point, radius, found,min,max)
    end
    return found
end


function QuadTree:inner_AutoMinMax(b)
    if b.center and b.size then 
        local min = vector2(b.center.x - b.size.x/2, b.center.y - b.size.y/2)
        local max = vector2(b.center.x + b.size.x/2, b.center.y + b.size.y/2)
        return min, max
    elseif b.min and b.max then
        return b.min, b.max
    elseif b.x and b.y and b.w and b.h then
        local min = vector2(b.x, b.y)
        local max = vector2(b.x + b.w, b.y + b.h)
        return min, max
    elseif b.x1 and b.y1 and b.x2 and b.y2 then
        local min = vector2(b.x1, b.y1)
        local max = vector2(b.x2, b.y2)
        return min, max
    elseif b.center and b.radius then
        local min = vector2(b.center.x - b.radius, b.center.y - b.radius)
        local max = vector2(b.center.x + b.radius, b.center.y + b.radius)
        return min, max
    else 
        error("invalid boundingbox of custom object",2)
    end
end
function QuadTree:GetCenter(min,max)
    return vector2((min.x + max.x)/2, (min.y + max.y)/2)
end

--not tested below
function QuadTree:insert_custom(catagary_name,custom_object)
    local min,max = self:inner_AutoMinMax(custom_object)
    if not self:inner_boundingbox_contains(min,max) then
        return false
    end
    if not self.custom_objects[catagary_name] then
        self.custom_objects[catagary_name] = {}
    end
    if #self.custom_objects[catagary_name] < self.capacity then
        custom_object.min,custom_object.max = min,max
        table.insert(self.custom_objects[catagary_name], custom_object)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_custom(catagary_name,custom_object) then
            return true
        elseif self.bottomright:insert_custom(catagary_name,custom_object) then
            return true
        elseif self.bottomleft:insert_custom(catagary_name,custom_object) then
            return true
        elseif self.topleft:insert_custom(catagary_name,custom_object) then
            return true
        end
    end
end

function QuadTree:remove_custom(catagary_name,custom_object)
    local min,max = self:inner_AutoMinMax(custom_object)
    if not self:inner_boundingbox_contains(min,max) then
        return false
    end
    if self.custom_objects[catagary_name] then
        for i, v in ipairs(self.custom_objects[catagary_name]) do
            if v == custom_object then
                table.remove(self.custom_objects[catagary_name], i)
                return true
            end
        end
    else 
        return false
    end
    if self.isdivided then
        if self.topright:remove_custom(catagary_name,custom_object) then
            return true
        elseif self.bottomright:remove_custom(catagary_name,custom_object) then
            return true
        elseif self.bottomleft:remove_custom(catagary_name,custom_object) then
            return true
        elseif self.topleft:remove_custom(catagary_name,custom_object) then
            return true
        end
    end
end

function QuadTree:query_custom_by_rectangle(catagary_name,rectrange, found,min,max)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    if self.custom_objects[catagary_name] then
        for i, custom_object in ipairs(self.custom_objects[catagary_name]) do
            if Contains.boundingboxtorectangle(custom_object, rectrange) then
                table.insert(found, custom_object)
            end
        end
    else 
        return found
    end
    if self.isdivided then
        self.topright:query_custom_by_rectangle(catagary_name,rectrange, found,min,max)
        self.bottomright:query_custom_by_rectangle(catagary_name,rectrange, found,min,max)
        self.bottomleft:query_custom_by_rectangle(catagary_name,rectrange, found,min,max)
        self.topleft:query_custom_by_rectangle(catagary_name,rectrange, found,min,max)
    end
    return found
end

function QuadTree:query_custom_by_point(catagary_name,point, radius, found,min,max)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    if self.custom_objects[catagary_name] then
        for i, custom_object in ipairs(self.custom_objects[catagary_name]) do
            if Contains.boundingboxtopoint(custom_object, point, radius) then
                table.insert(found, custom_object)
            end
        end
    else
        return found
    end
    if self.isdivided then
        self.topright:query_custom_by_point(catagary_name,point, radius, found,min,max)
        self.bottomright:query_custom_by_point(catagary_name,point, radius, found,min,max)
        self.bottomleft:query_custom_by_point(catagary_name,point, radius, found,min,max)
        self.topleft:query_custom_by_point(catagary_name,point, radius, found,min,max)
    end
    return found
end



function QuadTree:clear_custom(catagary_name)
    self.custom_objects[catagary_name] = {}
    if self.isdivided then
        self.topright:clear_custom(catagary_name)
        self.bottomright:clear_custom(catagary_name)
        self.bottomleft:clear_custom(catagary_name)
        self.topleft:clear_custom(catagary_name)
    end
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
function QuadTree:clear_circles()
    self.circles = {}
    if self.isdivided then
        self.topright:clear_circles()
        self.bottomright:clear_circles()
        self.bottomleft:clear_circles()
        self.topleft:clear_circles()
    end
end
function QuadTree:clear_boxes()
    self.boxes = {}
    if self.isdivided then
        self.topright:clear_boxes()
        self.bottomright:clear_boxes()
        self.bottomleft:clear_boxes()
        self.topleft:clear_boxes()
    end
end
function QuadTree:clear_boundingboxes()
    self.boundingboxes = {}
    if self.isdivided then
        self.topright:clear_boundingboxes()
        self.bottomright:clear_boundingboxes()
        self.bottomleft:clear_boundingboxes()
        self.topleft:clear_boundingboxes()
    end
end

function QuadTree:clear_all()
    self.points = {}
    self.circles = {}
    self.boxes = {}
    self.boundingboxes = {}
    self.custom_objects = {}
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
        if self.circles[1] then
            for i, circle in ipairs(self.circles) do
                DrawLine(circle.center.x,circle.center.y,drawz,circle.center.x,circle.center.y,drawz+2^10,r,g,255,a)
            end
        end
        if self.boxes[1] then
            for i, box in ipairs(self.boxes) do
                DrawLine(box.center.x,box.center.y,drawz,box.center.x,box.center.y,drawz+2^10,r,g,255,a)
            end
        end
        if self.boundingboxes[1] then
            for i, boundingbox in ipairs(self.boundingboxes) do
                DrawLine(boundingbox.center.x,boundingbox.center.y,drawz,boundingbox.center.x,boundingbox.center.y,drawz+2^10,r,g,255,a)
            end
        end
        for i,v in pairs(self.custom_objects) do 
            if v[1] then
                for i, obj in ipairs(v) do
                    local min,max = self:inner_AutoMinMax(obj)
                    local center = self:GetCenter(min,max)
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