-- MIT License
--
-- Copyright (c) 2017 Mikael Lind
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
-- See: https://github.com/elemel/polygraph

local polygraph = {}

local function distanceSquared2(x1, y1, x2, y2)
    return (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)
end

local Graph = {}
Graph.__index = Graph

function polygraph.newGraph(minVertexDistance)
    local graph = setmetatable({}, Graph)
    graph.minVertexDistance = minVertexDistance or 1e-3
    graph.polygons = {}
    graph.edges = {}
    graph.vertices = {}
    return graph
end

function Graph:addPolygon(...)
    local vertexData = {...}
    assert(#vertexData >= 6)
    assert(#vertexData % 2 == 0)

    local polygon = {
        vertices = {},
        edges = {},
        neighbors = {},
    }

    for i = 1, #vertexData, 2 do
        local x = vertexData[i]
        local y = vertexData[i + 1]
        local vertex = self:addVertex(x, y)
        vertex.polygons[polygon] = true
        table.insert(polygon.vertices, vertex)
    end

    local edges = {}
    local vertex1 = polygon.vertices[#polygon.vertices]

    for i, vertex2 in ipairs(polygon.vertices) do
        local edge = self:addEdge(vertex1, vertex2)
        local neighbor = next(edge.polygons)

        if neighbor then
            assert(not neighbor.neighbors[edge])
            polygon.neighbors[edge] = neighbor
            neighbor.neighbors[edge] = polygon
        end

        edge.polygons[polygon] = true
        table.insert(polygon.edges, edge)
        vertex1 = vertex2
    end

    self.polygons[polygon] = true
    return polygon
end

function Graph:addEdge(vertex1, vertex2)
    local edge = vertex1.neighbors[vertex2]

    if edge then
        assert(edge == vertex2.neighbors[vertex1])
        return edge
    end

    edge = {
        vertices = {vertex1 = vertex2, vertex2 = vertex1},
        neighbors = {},
        polygons = {},
    }

    vertex1.neighbors[vertex2] = edge
    vertex2.neighbors[vertex1] = edge
    vertex1.edges[edge] = vertex2
    vertex2.edges[edge] = vertex1
    self.edges[edge] = true
    return edge
end

function Graph:addVertex(x, y)
    local minVertexDistanceSquared = self.minVertexDistance * self.minVertexDistance

    for vertex, _ in pairs(self.vertices) do
        if distanceSquared2(x, y, vertex.x, vertex.y) < minVertexDistanceSquared then
            return vertex
        end
    end

    local vertex = {
        x = x,
        y = y,
        neighbors = {},
        edges = {},
        polygons = {},
    }

    self.vertices[vertex] = true
    return vertex
end

return polygraph
