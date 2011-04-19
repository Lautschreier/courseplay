-- based on http://planet-ls.de/board/index.php?page=Thread&threadID=6886
-- thanks @ face

CourseplayEvent = {};
CourseplayEvent_mt = Class(CourseplayEvent, Event);

InitEventClass(CourseplayEvent, "CourseplayEvent");

function CourseplayEvent:emptyNew()  -- hier wir ein leeres Event objekt erzeugt
    local self = Event:new(CourseplayEvent_mt );
    self.className="CourseplayEvent";
    return self;
end;

function CourseplayEvent:new(vehicle, method, value) -- Der konsturktor des Events (erzeugt eben ein neues Event). Wir wollen das vehicle (aufrufer) und die neue richtung speichern bzw. übertragen
    self.vehicle = vehicle;
    self.method = method;
    self.value = value;
    return self;
end;

function CourseplayEvent:readStream(streamId, connection)  -- wird aufgerufen wenn mich ein Event erreicht
    local id = streamReadInt32(streamId); -- hier lesen wir die übertragene ID des vehicles aus
    self.method = streamReadString(streamId); -- hier lesen wir die neue direction aus (es handelt sich hierbei um einen Bool (true/false)
    self.vehicle = networkGetObject(id); -- wir wandeln nunn die ID des vehicles in das passende Objekt um
    self:run(connection);  -- das event wurde komplett empfangen und kann nun "ausgeführt" werden
end;

function CourseplayEvent:writeStream(streamId, connection)   -- Wird aufgrufen wenn ich ein event verschicke (merke: reihenfolge der Daten muss mit der bei readStream übereinstimmen (z.B. hier: erst die Vehicle-Id und dann die Courseplay senden, und bei Readstream dann eben erst die vehicleId lesen und dann die Courseplay)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));	-- wir übertragen das Vehicle in form seiner ID
    streamWriteBool(streamId, self.direction );   -- wir übertragen die neue direction
end;

function CourseplayEvent:run(connection)  -- wir führen das empfangene event aus
    self.vehicle:setRotateDirection(self.direction, true); -- wir rufen die funktion setRotateDirection auf, damit auch hier bei uns die drehrichtung geändert wird. Das true ist hier wichtig, dann wir haben ein event erhalten, d.h. wir brauchen es nicht mehr versenden, weil es alle anderen mitpsieler schon erreicht hat! Das true also hier nie vergessen!!!!!!
	if not connection:getIsServer() then  -- wenn der Empfänger des Events der Server ist, dann soll er das Event an alle anderen Clients schicken
		g_server:broadcastEvent(CourseplayEvent:new(self.vehicle, self.direction), nil, connection, self.object);
	end;
end;

function CourseplayEvent.sendEvent(vehicle, direction, noEventSend)  -- hilfsfunktion, die Events anstößte (wirde von setRotateDirection in der Spezi aufgerufen)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then   -- wenn wir der Server sind dann schicken wir das event an alle clients
			g_server:broadcastEvent(CourseplayEvent:new(vehicle, direction), nil, nil, vehicle);
		else -- wenn wir ein Client sind dann schicken wir das event zum server
			g_client:getServerConnection():sendEvent(CourseplayEvent:new(vehicle, directiont));
		end;
	end;
end;