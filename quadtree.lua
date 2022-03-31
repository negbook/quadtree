QuadTree = {}
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
        boxes = {},
        polygons = {},
        isdivided = false
    }, {
        __index = QuadTree,
        __tostring = function(self)
            return "QuadTree: center: "..self.center.x.." "..self.center.y.." width: "..self.width.." height: "..self.height.." capacity: "..self.capacity.." points: "..#self.points.. " boxes: "..#self.boxes.. " polygons: "..#self.polygons.. " isdivided: "..tostring(self.isdivided)
            
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

function QuadTree:query_points_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, point in ipairs(self.points) do
        table.insert(found, point)
    end
    if self.isdivided then
        self.topright:query_points_by_rectangle(rectrange, found)
        self.bottomright:query_points_by_rectangle(rectrange, found)
        self.bottomleft:query_points_by_rectangle(rectrange, found)
        self.topleft:query_points_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_points_by_circle(circle_center, radius, found)
    found = found or {}
    if not self:inner_point_contains(circle_center, radius) then
        return found
    end
    for i, point in ipairs(self.points) do
        if (point.x - circle_center.x)^2 + (point.y - circle_center.y)^2 <= radius^2 then
            table.insert(found, point)
        end
    end
    if self.isdivided then
        self.topright:query_points_by_circle(circle_center, radius, found)
        self.bottomright:query_points_by_circle(circle_center, radius, found)
        self.bottomleft:query_points_by_circle(circle_center, radius, found)
        self.topleft:query_points_by_circle(circle_center, radius, found)
    end
    return found
end

function QuadTree:query_points_by_point(point, found)
    found = found or {}
    if not self:inner_point_contains(point) then
        return found
    end
    for i, point in ipairs(self.points) do
        table.insert(found, point)
    end
    if self.isdivided then
        self.topright:query_points_by_point(point, found)
        self.bottomright:query_points_by_point(point, found)
        self.bottomleft:query_points_by_point(point, found)
        self.topleft:query_points_by_point(point, found)
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

function QuadTree:query_boxes_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        table.insert(found, box)
    end
    if self.isdivided then
        self.topright:query_boxes_by_rectangle(rectrange, found)
        self.bottomright:query_boxes_by_rectangle(rectrange, found)
        self.bottomleft:query_boxes_by_rectangle(rectrange, found)
        self.topleft:query_boxes_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_boxes_by_circle(circle_center, radius, found)
    found = found or {}
    if not self:inner_point_contains(circle_center, radius) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        if (box.center.x - circle_center.x)^2 + (box.center.y - circle_center.y)^2 <= radius^2 then
            table.insert(found, box)
        end
    end
    if self.isdivided then
        self.topright:query_boxes_by_circle(circle_center, radius, found)
        self.bottomright:query_boxes_by_circle(circle_center, radius, found)
        self.bottomleft:query_boxes_by_circle(circle_center, radius, found)
        self.topleft:query_boxes_by_circle(circle_center, radius, found)
    end
    return found
end

function QuadTree:query_boxes_by_point(point, found)
    found = found or {}
    if not self:inner_point_contains(point) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        table.insert(found, box)
    end
    if self.isdivided then
        self.topright:query_boxes_by_point(point, found)
        self.bottomright:query_boxes_by_point(point, found)
        self.bottomleft:query_boxes_by_point(point, found)
        self.topleft:query_boxes_by_point(point, found)
    end
    return found
end

function QuadTree:inner_polygon_contains(vertices)
    local minx, maxx = math.huge, -math.huge
    local miny, maxy = math.huge, -math.huge
    for i, vertex in ipairs(vertices) do
        minx = math.min(minx, vertex.x)
        maxx = math.max(maxx, vertex.x)
        miny = math.min(miny, vertex.y)
        maxy = math.max(maxy, vertex.y)
    end
    return minx >= self.center.x - self.width/2 and maxx <= self.center.x + self.width/2 and miny >= self.center.y - self.height/2 and maxy <= self.center.y + self.height/2
end


function QuadTree:insert_polygon(vertices)
    if not self:inner_polygon_contains(vertices) then
        return false
    end
    if #self.polygons < self.capacity then
        table.insert(self.polygons, vertices)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_polygon(vertices) then
            return true
        elseif self.bottomright:insert_polygon(vertices) then
            return true
        elseif self.bottomleft:insert_polygon(vertices) then
            return true
        elseif self.topleft:insert_polygon(vertices) then
            return true
        end
    end
end

function QuadTree:query_polygons_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, vertices in ipairs(self.polygons) do
        table.insert(found, vertices)
    end
    if self.isdivided then
        self.topright:query_polygons_by_rectangle(rectrange, found)
        self.bottomright:query_polygons_by_rectangle(rectrange, found)
        self.bottomleft:query_polygons_by_rectangle(rectrange, found)
        self.topleft:query_polygons_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_polygons_by_circle(circle_center, radius, found)
    found = found or {}
    if not self:inner_point_contains(circle_center, radius) then
        return found
    end
    for i, vertices in ipairs(self.polygons) do
        if (vertices[1].x - circle_center.x)^2 + (vertices[1].y - circle_center.y)^2 <= radius^2 then
            table.insert(found, vertices)
        end
    end
    if self.isdivided then
        self.topright:query_polygons_by_circle(circle_center, radius, found)
        self.bottomright:query_polygons_by_circle(circle_center, radius, found)
        self.bottomleft:query_polygons_by_circle(circle_center, radius, found)
        self.topleft:query_polygons_by_circle(circle_center, radius, found)
    end
    return found
end

function QuadTree:query_polygons_by_point(point, found)
    return self:query_polygons_by_circle(point, 0, found)
end

function QuadTree:query_points_boxes_polygons_by_rectangle(rectrange, found)
    found = found or {
        boxes = {},
        polygons = {},
        points = {}
    }
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, point in ipairs(self.points) do
        table.insert(found.points, point)
    end
    for i, box in ipairs(self.boxes) do
        table.insert(found.boxes, box)
    end
    for i, vertices in ipairs(self.polygons) do
        table.insert(found.polygons, vertices)
    end
    if self.isdivided then
        self.topright:query_points_boxes_polygons_by_rectangle(rectrange, found)
        self.bottomright:query_points_boxes_polygons_by_rectangle(rectrange, found)
        self.bottomleft:query_points_boxes_polygons_by_rectangle(rectrange, found)
        self.topleft:query_points_boxes_polygons_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_points_boxes_polygons_by_circle(circle_center, radius, found)
    found = found or {
        boxes = {},
        polygons = {},
        points = {}
    }
    if not self:inner_point_contains(circle_center, radius) then
        return found
    end
    for i, point in ipairs(self.points) do
        if (point.x - circle_center.x)^2 + (point.y - circle_center.y)^2 <= radius^2 then
            table.insert(found.points, point)
        end
    end
    for i, box in ipairs(self.boxes) do
        table.insert(found.boxes, box)
    end
    for i, vertices in ipairs(self.polygons) do
        if (vertices[1].x - circle_center.x)^2 + (vertices[1].y - circle_center.y)^2 <= radius^2 then
            table.insert(found.polygons, vertices)
        end
    end
    if self.isdivided then
        self.topright:query_points_boxes_polygons_by_circle(circle_center, radius, found)
        self.bottomright:query_points_boxes_polygons_by_circle(circle_center, radius, found)
        self.bottomleft:query_points_boxes_polygons_by_circle(circle_center, radius, found)
        self.topleft:query_points_boxes_polygons_by_circle(circle_center, radius, found)
    end
    return found
end

function QuadTree:query_points_boxes_polygons_by_point(point, found)
    return self:query_points_boxes_polygons_by_circle(point, 0, found)
end

