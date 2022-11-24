class.PlaceManager()

--  {
--      display_name= "Decorator",
--      is_visor= false,
--      connected_at= 1643407779.0,
--      agent_id= "123",
--      avatar_id= "123",
--      stats= "asdf"
--  }

function PlaceManager:_init(app)
    self.app = app
    self.agents = {}
    self.apps = {}
    self.users = {}

    self.onAgentAdded = function(agent) end
    self.onAgentUpdated = function(agent) end
    self.onAgentRemoved = function(agent) end
    self.onUserAdded = function(agent) end
    self.onUserUpdated = function(agent) end
    self.onUserRemoved = function(agent) end
    self.onAppAdded = function(agent) end
    self.onAppUpdated = function(agent) end
    self.onAppRemoved = function(agent) end
end

function PlaceManager:refresh()
    app.client:sendInteraction({
        receiver_entity_id = "place",
        body = {
            "list_agents"
        }
    }, function(resp, body)
        if body[1] ~= "list_agents" and body[2] ~= "ok" then return end
        self:_setData(body[3])
    end)
end

function PlaceManager:getAgent(aid)
    return self.agents[aid]
end

function PlaceManager:_setData(data)
    local newAgents = {}
    for _, agent in ipairs(data) do
        local existing = self:getAgent(agent.agent_id)
        newAgents[agent.agent_id] = agent
        if not existing then
            setmetatable(agent, PlaceAgent)
            agent.app = self.app
            agent.manager = self
            self.agents[agent.agent_id] = agent
            self.onAgentAdded(agent)
            if agent.is_visor then
                self.users[agent.agent_id] = agent
                self.onUserAdded(agent)
            else
                self.apps[agent.agent_id] = agent
                self.onAppAdded(agent)
            end
        else
            tablex.update(existing, agent)
            self.onAgentUpdated(existing)
            if agent.is_visor then
                self.onUserUpdated(existing)
            else
                self.onAppUpdated(existing)
            end
        end
    end
    for aid, agent in pairs(self.agents) do
        local newAgent = newAgents[aid]
        if not newAgent then
            self.agents[aid] = nil
            self.onAgentRemoved(agent)
            if agent.is_visor then
                self.users[aid] = nil
                self.onUserRemoved(agent)
            else
                self.apps[aid] = nil
                self.onAppRemoved(agent)
            end
        end
    end
end

class.PlaceAgent()
function PlaceAgent:quit(cb)
    if not self.avatar_id then
        cb(false)
        return
    end
    self.app.client:sendInteraction({
        receiver_entity_id = self.avatar_id,
        body = {
            "quit"
        }
    }, function(resp, body)
        if body[2] ~= "ok" then
            cb(false)
        else
            cb(true)
            self.manager:refresh()
        end
    end)
end

function PlaceAgent:kill(cb)
    self.app.client:sendInteraction({
        receiver_entity_id = "place",
        body = {
            "kick_agent",
            self.agent_id
        }
    }, function(resp, body)
        if body[2] ~= "ok" then
            cb(false)
        else
            cb(true)
            self.manager:refresh()
        end
    end)
end

function PlaceAgent:teleportUser(user_avatar, cb)
    self.app.client:getEntity(self.avatar_id, function(app_entity)
        local m = app_entity.components.transform:transformFromWorld()
        local pos = m * vec3.new()
        -- some apps don't have an origin on the floor, so move the destination point down
        -- if we're teleporting to a user though, make sure we def end up in front of them
        if not self.is_visor then
            pos.y = 0
        end
        local trans = mat4.translate(mat4.identity(), mat4.identity(), pos)
        local rot = mat4.from_quaternion(m:to_quat())
        --rot:rotate(rot, 3.14, vec3(0,1,0)) -- face TOWARDS thing
        local invRot = mat4.invert(mat4.new(), rot)
        
        local moved_back = mat4.identity()
        moved_back:translate(moved_back, vec3(0,0,1.5))

        local new_transform = mat4.identity()
        new_transform:rotate(new_transform, 3.14/2, vec3(0,1,0))
        
        self.app.client:sendInteraction({
            receiver_entity_id = user_avatar.id,
            body = {
                "teleport",
                Pose(new_transform):tojson()
            }
        }, function(resp, body)
            if body[2] ~= "ok" then
                cb(false)
            else
                cb(true)
            end
        end)
    end)
end

function PlaceAgent:sendPingFrom(sender_avatar, cb)
    local senderName = "a user"
    self.app.client:sendInteraction({
        receiver_entity_id = self.avatar_id,
        body = {
            "post_notification",
            {
                title= "Ping from "..senderName.."!",
                body= "hello hello!"
            }
        }
    }, function(resp, body)
        if body[2] ~= "ok" then
            cb(false)
        else
            cb(true)
        end
    end)
end

return PlaceManager
