--[[
TODO:
- Bait crate purchasables
- Auto appraise: select equipped fish or all by rarity, min weight, min cash
- Auto totem: sundial, aurora
- Area farming (waterfall, the depths)
jeszcze cus?
]]

repeat task.wait() until game:IsLoaded()
local HOME_DIR = "kiciahook/fisch"

-- // Interface
if not LPH_OBFUSCATED then
	LPH_NO_VIRTUALIZE = function(...) return ... end
	LPH_NO_UPVALUES = function(...) return ... end
	LPH_JIT_MAX = function(...) return ... end
	LPH_JIT = function(...) return ... end
else
    print = function() end
    warn = function() end
end

local function safeRef(ref)
	return cloneref and cloneref(ref) or ref
end

local fireproximityprompt = fireproximityprompt or function(ProximityPrompt, Amount, Skip)
	assert(ProximityPrompt, "Argument #1 Missing or nil")
	assert(typeof(ProximityPrompt) == "Instance" and ProximityPrompt:IsA("ProximityPrompt"), "Attempted to fire a Value that is not a ProximityPrompt")

	local HoldDuration = ProximityPrompt.HoldDuration
	if Skip then
		ProximityPrompt.HoldDuration = 0
	end

	for i = 1, Amount or 1 do
		ProximityPrompt:InputHoldBegin()
		if Skip then
			local RunService = game:GetService("RunService")
			local Start = time()
			repeat
				RunService.Heartbeat:Wait(0.1)
			until time() - Start > HoldDuration
		end
		ProximityPrompt:InputHoldEnd()
	end
	ProximityPrompt.HoldDuration = HoldDuration
end

local setidentity = setthreadcontext or setthreadidentity or set_thread_identity or set_thread_context or setidentity

local Debris = safeRef(game:GetService("Debris"))
local GuiService: GuiService = safeRef(game:GetService("GuiService"))
local Players: Players = safeRef(game:GetService("Players"))
local RunService: RunService = safeRef(game:GetService("RunService"))
local UserInputService: UserInputService = safeRef(game:GetService("UserInputService"))
local ReplicatedStorage: ReplicatedStorage = safeRef(game:GetService("ReplicatedStorage"))
local CoreGui: CoreGui = safeRef(game:GetService("CoreGui"))
local HttpService: HttpService = safeRef(game:GetService("HttpService"))
local Lighting: Lighting = safeRef(game:GetService("Lighting"))
local ContentProvider: ContentProvider = safeRef(game:GetService("ContentProvider"))
local TweenService: TweenService = safeRef(game:GetService("TweenService"))
local CollectionService: CollectionService = safeRef(game:GetService("CollectionService"))
local ScriptContext: ScriptContext = safeRef(game:GetService("ScriptContext"))
local StarterGui: StarterGui = safeRef(game:GetService("StarterGui"))
local GuiService: GuiService = safeRef(game:GetService("GuiService"))
local TeleportService: TeleportService = safeRef(game:GetService("TeleportService"))
local VirtualInputManager = Instance.new("VirtualInputManager")

local LocalPlayer: LocalPlayer = Players.LocalPlayer
local PlayerGui: PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local CurrentCamera = workspace.CurrentCamera

local Trove = (function()
	--!strict

export type Trove = {
	Extend: (self: Trove) -> Trove,
	Clone: <T>(self: Trove, instance: T & Instance) -> T,
	Construct: <T, A...>(self: Trove, class: Constructable<T, A...>, A...) -> T,
	Connect: (self: Trove, signal: SignalLike | RBXScriptSignal, fn: (...any) -> ...any) -> ConnectionLike,
	BindToRenderStep: (self: Trove, name: string, priority: number, fn: (dt: number) -> ()) -> (),
	AddPromise: <T>(self: Trove, promise: T & PromiseLike) -> T,
	Add: <T>(self: Trove, object: T & Trackable, cleanupMethod: string?) -> T,
	Remove: <T>(self: Trove, object: T & Trackable) -> boolean,
	Clean: (self: Trove) -> (),
	AttachToInstance: (self: Trove, instance: Instance) -> RBXScriptConnection,
	Destroy: (self: Trove) -> (),
}

type TroveInternal = Trove & {
	_objects: { any },
	_cleaning: boolean,
	_findAndRemoveFromObjects: (self: TroveInternal, object: any, cleanup: boolean) -> boolean,
	_cleanupObject: (self: TroveInternal, object: any, cleanupMethod: string?) -> (),
}

--[=[
	@within Trove
	@type Trackable Instance | ConnectionLike | PromiseLike | thread | ((...any) -> ...any) | Destroyable | DestroyableLowercase | Disconnectable | DisconnectableLowercase
	Represents all trackable objects by Trove.
]=]
export type Trackable =
	Instance
	| ConnectionLike
	| PromiseLike
	| thread
	| ((...any) -> ...any)
	| Destroyable
	| DestroyableLowercase
	| Disconnectable
	| DisconnectableLowercase

--[=[
	@within Trove
	@interface ConnectionLike
	.Connected boolean
	.Disconnect (self) -> ()
]=]
type ConnectionLike = {
	Connected: boolean,
	Disconnect: (self: ConnectionLike) -> (),
}

--[=[
	@within Trove
	@interface SignalLike
	.Connect (self, callback: (...any) -> ...any) -> ConnectionLike
	.Once (self, callback: (...any) -> ...any) -> ConnectionLike
]=]
type SignalLike = {
	Connect: (self: SignalLike, callback: (...any) -> ...any) -> ConnectionLike,
	Once: (self: SignalLike, callback: (...any) -> ...any) -> ConnectionLike,
}

--[=[
	@within Trove
	@interface PromiseLike
	.getStatus (self) -> string
	.finally (self, callback: (...any) -> ...any) -> PromiseLike
	.cancel (self) -> ()
]=]
type PromiseLike = {
	getStatus: (self: PromiseLike) -> string,
	finally: (self: PromiseLike, callback: (...any) -> ...any) -> PromiseLike,
	cancel: (self: PromiseLike) -> (),
}

--[=[
	@within Trove
	@type Constructable { new: (A...) -> T } | (A...) -> T
]=]
type Constructable<T, A...> = { new: (A...) -> T } | (A...) -> T

--[=[
	@within Trove
	@interface Destroyable
	.disconnect (self) -> ()
]=]
type Destroyable = {
	Destroy: (self: Destroyable) -> (),
}

--[=[
	@within Trove
	@interface DestroyableLowercase
	.disconnect (self) -> ()
]=]
type DestroyableLowercase = {
	destroy: (self: DestroyableLowercase) -> (),
}

--[=[
	@within Trove
	@interface Disconnectable
	.disconnect (self) -> ()
]=]
type Disconnectable = {
	Disconnect: (self: Disconnectable) -> (),
}

--[=[
	@within Trove
	@interface DisconnectableLowercase
	.disconnect (self) -> ()
]=]
type DisconnectableLowercase = {
	disconnect: (self: DisconnectableLowercase) -> (),
}

local FN_MARKER = newproxy()
local THREAD_MARKER = newproxy()
local GENERIC_OBJECT_CLEANUP_METHODS = table.freeze({ "Destroy", "Disconnect", "destroy", "disconnect" })

local function GetObjectCleanupFunction(object: any, cleanupMethod: string?)
	local t = typeof(object)

	if t == "function" then
		return FN_MARKER
	elseif t == "thread" then
		return THREAD_MARKER
	end

	if cleanupMethod then
		return cleanupMethod
	end

	if t == "Instance" then
		return "Destroy"
	elseif t == "RBXScriptConnection" then
		return "Disconnect"
	elseif t == "table" then
		for _, genericCleanupMethod in GENERIC_OBJECT_CLEANUP_METHODS do
			if typeof(object[genericCleanupMethod]) == "function" then
				return genericCleanupMethod
			end
		end
	end

	error(("failed to get cleanup function for object %s: %s"):format(t, object), 3)
end

local function AssertPromiseLike(object: any)
	if
		typeof(object) ~= "table"
		or typeof(object.getStatus) ~= "function"
		or typeof(object.finally) ~= "function"
		or typeof(object.cancel) ~= "function"
	then
		error("did not receive a promise as an argument", 3)
	end
end

--[=[
	@class Trove
	A Trove is helpful for tracking any sort of object during
	runtime that needs to get cleaned up at some point.
]=]
local Trove = {}
Trove.__index = Trove

--[=[
	@return Trove
	Constructs a Trove object.

	```lua
	local trove = Trove.new()
	```
]=]
function Trove.new(): Trove
	local self = setmetatable({}, Trove)

	self._objects = {}
	self._cleaning = false

	return (self :: any) :: Trove
end

--[=[
	@method Add
	@within Trove
	@param object any -- Object to track
	@param cleanupMethod string? -- Optional cleanup name override
	@return object: any
	Adds an object to the trove. Once the trove is cleaned or
	destroyed, the object will also be cleaned up.

	The following types are accepted (e.g. `typeof(object)`):

	| Type | Cleanup |
	| ---- | ------- |
	| `Instance` | `object:Destroy()` |
	| `RBXScriptConnection` | `object:Disconnect()` |
	| `function` | `object()` |
	| `thread` | `task.cancel(object)` |
	| `table` | `object:Destroy()` _or_ `object:Disconnect()` _or_ `object:destroy()` _or_ `object:disconnect()` |
	| `table` with `cleanupMethod` | `object:<cleanupMethod>()` |

	Returns the object added.

	```lua
	-- Add a part to the trove, then destroy the trove,
	-- which will also destroy the part:
	local part = Instance.new("Part")
	trove:Add(part)
	trove:Destroy()

	-- Add a function to the trove:
	trove:Add(function()
		print("Cleanup!")
	end)
	trove:Destroy()

	-- Standard cleanup from table:
	local tbl = {}
	function tbl:Destroy()
		print("Cleanup")
	end
	trove:Add(tbl)

	-- Custom cleanup from table:
	local tbl = {}
	function tbl:DoSomething()
		print("Do something on cleanup")
	end
	trove:Add(tbl, "DoSomething")
	```
]=]
function Trove.Add(self: TroveInternal, object: Trackable, cleanupMethod: string?): any
	if self._cleaning then
		error("cannot call trove:Add() while cleaning", 2)
	end

	local cleanup = GetObjectCleanupFunction(object, cleanupMethod)
	table.insert(self._objects, { object, cleanup })

	return object
end

--[=[
	@method Clone
	@within Trove
	@return Instance
	Clones the given instance and adds it to the trove. Shorthand for
	`trove:Add(instance:Clone())`.

	```lua
	local clonedPart = trove:Clone(somePart)
	```
]=]
function Trove.Clone(self: TroveInternal, instance: Instance): Instance
	if self._cleaning then
		error("cannot call trove:Clone() while cleaning", 2)
	end

	return self:Add(instance:Clone())
end

--[=[
	@method Construct
	@within Trove
	@param class { new(Args...) -> T } | (Args...) -> T
	@param ... Args...
	@return T
	Constructs a new object from either the
	table or function given.

	If a table is given, the table"s `new`
	function will be called with the given
	arguments.

	If a function is given, the function will
	be called with the given arguments.

	The result from either of the two options
	will be added to the trove.

	This is shorthand for `trove:Add(SomeClass.new(...))`
	and `trove:Add(SomeFunction(...))`.

	```lua
	local Signal = require(somewhere.Signal)

	-- All of these are identical:
	local s = trove:Construct(Signal)
	local s = trove:Construct(Signal.new)
	local s = trove:Construct(function() return Signal.new() end)
	local s = trove:Add(Signal.new())

	-- Even Roblox instances can be created:
	local part = trove:Construct(Instance, "Part")
	```
]=]
function Trove.Construct<T, A...>(self: TroveInternal, class: Constructable<T, A...>, ...: A...)
	if self._cleaning then
		error("Cannot call trove:Construct() while cleaning", 2)
	end

	local object = nil
	local t = type(class)
	if t == "table" then
		object = (class :: any).new(...)
	elseif t == "function" then
		object = (class :: any)(...)
	end

	return self:Add(object)
end

--[=[
	@method Connect
	@within Trove
	@param signal RBXScriptSignal
	@param fn (...: any) -> ()
	@return RBXScriptConnection
	Connects the function to the signal, adds the connection
	to the trove, and then returns the connection.

	This is shorthand for `trove:Add(signal:Connect(fn))`.

	```lua
	trove:Connect(workspace.ChildAdded, function(instance)
		print(instance.Name .. " added to workspace")
	end)
	```
]=]
function Trove.Connect(self: TroveInternal, signal: SignalLike, fn: (...any) -> ...any)
	if self._cleaning then
		error("Cannot call trove:Connect() while cleaning", 2)
	end

	return self:Add(signal:Connect(fn))
end

--[=[
	@method BindToRenderStep
	@within Trove
	@param name string
	@param priority number
	@param fn (dt: number) -> ()
	Calls `RunService:BindToRenderStep` and registers a function in the
	trove that will call `RunService:UnbindFromRenderStep` on cleanup.

	```lua
	trove:BindToRenderStep("Test", Enum.RenderPriority.Last.Value, function(dt)
		-- Do something
	end)
	```
]=]
function Trove.BindToRenderStep(self: TroveInternal, name: string, priority: number, fn: (dt: number) -> ())
	if self._cleaning then
		error("cannot call trove:BindToRenderStep() while cleaning", 2)
	end

	RunService:BindToRenderStep(name, priority, fn)

	self:Add(function()
		RunService:UnbindFromRenderStep(name)
	end)
end

--[=[
	@method AddPromise
	@within Trove
	@param promise Promise
	@return Promise
	Gives the promise to the trove, which will cancel the promise if the trove is cleaned up or if the promise
	is removed. The exact promise is returned, thus allowing chaining.

	```lua
	trove:AddPromise(doSomethingThatReturnsAPromise())
		:andThen(function()
			print("Done")
		end)
	-- Will cancel the above promise (assuming it didn"t resolve immediately)
	trove:Clean()

	local p = trove:AddPromise(doSomethingThatReturnsAPromise())
	-- Will also cancel the promise
	trove:Remove(p)
	```

	:::caution Promise v4 Only
	This is only compatible with the [roblox-lua-promise](https://eryn.io/roblox-lua-promise/) library, version 4.
	:::
]=]
function Trove.AddPromise(self: TroveInternal, promise: PromiseLike)
	if self._cleaning then
		error("cannot call trove:AddPromise() while cleaning", 2)
	end
	AssertPromiseLike(promise)

	if promise:getStatus() == "Started" then
		promise:finally(function()
			if self._cleaning then
				return
			end
			self:_findAndRemoveFromObjects(promise, false)
		end)

		self:Add(promise, "cancel")
	end

	return promise
end

--[=[
	@method Remove
	@within Trove
	@param object any
	Removes the object from the Trove and cleans it up.

	```lua
	local part = Instance.new("Part")
	trove:Add(part)
	trove:Remove(part)
	```
]=]
function Trove.Remove(self: TroveInternal, object: Trackable): boolean
	if self._cleaning then
		error("cannot call trove:Remove() while cleaning", 2)
	end

	return self:_findAndRemoveFromObjects(object, true)
end

--[=[
	@method Extend
	@within Trove
	@return Trove
	Creates and adds another trove to itself. This is just shorthand
	for `trove:Construct(Trove)`. This is useful for contexts where
	the trove object is present, but the class itself isn"t.

	:::note
	This does _not_ clone the trove. In other words, the objects in the
	trove are not given to the new constructed trove. This is simply to
	construct a new Trove and add it as an object to track.
	:::

	```lua
	local trove = Trove.new()
	local subTrove = trove:Extend()

	trove:Clean() -- Cleans up the subTrove too
	```
]=]
function Trove.Extend(self: TroveInternal)
	if self._cleaning then
		error("cannot call trove:Extend() while cleaning", 2)
	end

	return self:Construct(Trove)
end

--[=[
	@method Clean
	@within Trove
	Cleans up all objects in the trove. This is
	similar to calling `Remove` on each object
	within the trove. The ordering of the objects
	removed is _not_ guaranteed.

	```lua
	trove:Clean()
	```
]=]
function Trove.Clean(self: TroveInternal)
	if self._cleaning then
		return
	end

	self._cleaning = true

	for _, obj in self._objects do
		self:_cleanupObject(obj[1], obj[2])
	end

	table.clear(self._objects)
	self._cleaning = false
end

function Trove._findAndRemoveFromObjects(self: TroveInternal, object: any, cleanup: boolean): boolean
	local objects = self._objects

	for i, obj in ipairs(objects) do
		if obj[1] == object then
			local n = #objects
			objects[i] = objects[n]
			objects[n] = nil

			if cleanup then
				self:_cleanupObject(obj[1], obj[2])
			end

			return true
		end
	end

	return false
end

function Trove._cleanupObject(_self: TroveInternal, object: any, cleanupMethod: string?)
	if cleanupMethod == FN_MARKER then
		object()
	elseif cleanupMethod == THREAD_MARKER then
		pcall(task.cancel, object)
	else
		object[cleanupMethod](object)
	end
end

--[=[
	@method AttachToInstance
	@within Trove
	@param instance Instance
	@return RBXScriptConnection
	Attaches the trove to a Roblox instance. Once this
	instance is removed from the game (parent or ancestor"s
	parent set to `nil`), the trove will automatically
	clean up.

	This inverses the ownership of the Trove object, and should
	only be used when necessary. In other words, the attached
	instance dictates when the trove is cleaned up, rather than
	the trove dictating the cleanup of the instance.

	:::caution
	Will throw an error if `instance` is not a descendant
	of the game hierarchy.
	:::

	```lua
	trove:AttachToInstance(somePart)
	trove:Add(function()
		print("Cleaned")
	end)

	-- Destroying the part will cause the trove to clean up, thus "Cleaned" printed:
	somePart:Destroy()
	```
]=]
function Trove.AttachToInstance(self: TroveInternal, instance: Instance)
	if self._cleaning then
		error("cannot call trove:AttachToInstance() while cleaning", 2)
	elseif not instance:IsDescendantOf(game) then
		error("instance is not a descendant of the game hierarchy", 2)
	end

	return self:Connect(instance.Destroying, function()
		self:Destroy()
	end)
end

--[=[
	@method Destroy
	@within Trove
	Alias for `trove:Clean()`.

	```lua
	trove:Destroy()
	```
]=]
function Trove.Destroy(self: TroveInternal)
	self:Clean()
end

return {
	new = Trove.new,
}
end)()
type Trove = Trove.Trove

local Signal = (function()
-- -----------------------------------------------------------------------------
--               Batched Yield-Safe Signal Implementation                     --
-- This is a Signal class which has effectively identical behavior to a       --
-- normal RBXScriptSignal, with the only difference being a couple extra      --
-- stack frames at the bottom of the stack trace when an error is thrown.     --
-- This implementation caches runner coroutines, so the ability to yield in   --
-- the signal handlers comes at minimal extra cost over a naive signal        --
-- implementation that either always or never spawns a thread.                --
--                                                                            --
-- License:                                                                   --
--   Licensed under the MIT license.                                          --
--                                                                            --
-- Authors:                                                                   --
--   stravant - July 31st, 2021 - Created the file.                           --
--   sleitnick - August 3rd, 2021 - Modified for Knit.                        --
-- -----------------------------------------------------------------------------

-- Signal types
export type Connection = {
	Disconnect: (self: Connection) -> (),
	Destroy: (self: Connection) -> (),
	Connected: boolean,
}

export type Signal<T...> = {
	Fire: (self: Signal<T...>, T...) -> (),
	FireDeferred: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	DisconnectAll: (self: Signal<T...>) -> (),
	GetConnections: (self: Signal<T...>) -> { Connection },
	Destroy: (self: Signal<T...>) -> (),
	Wait: (self: Signal<T...>) -> T...,
}

-- The currently idle thread to run the next handler on
local freeRunnerThread = nil

-- Function which acquires the currently idle handler runner thread, runs the
-- function fn on it, and then releases the thread, returning it to being the
-- currently idle one.
-- If there was a currently idle runner thread already, that"s okay, that old
-- one will just get thrown and eventually GCed.
local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

-- Coroutine runner that we create coroutines of. The coroutine can be
-- repeatedly resumed with functions to run followed by the argument to run
-- them with.
local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

--[=[
	@within Signal
	@interface SignalConnection
	.Connected boolean
	.Disconnect (SignalConnection) -> ()

	Represents a connection to a signal.
	```lua
	local connection = signal:Connect(function() end)
	print(connection.Connected) --> true
	connection:Disconnect()
	print(connection.Connected) --> false
	```
]=]

-- Connection class
local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	-- Unhook the node, but DON"T clear it. That way any fire calls that are
	-- currently sitting on this node will be able to iterate forwards off of
	-- it, but any subsequent fire calls will not hit it, and it will be GCed
	-- when no more fire calls are sitting on it.
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

Connection.Destroy = Connection.Disconnect

-- Make Connection strict
setmetatable(Connection, {
	__index = function(_tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_tb, key, _value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

--[=[
	@within Signal
	@type ConnectionFn (...any) -> ()

	A function connected to a signal.
]=]

--[=[
	@class Signal

	A Signal is a data structure that allows events to be dispatched
	and observed.

	This implementation is a direct copy of the de facto standard, [GoodSignal](https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063),
	with some added methods and typings.

	For example:
	```lua
	local signal = Signal.new()

	-- Subscribe to a signal:
	signal:Connect(function(msg)
		print("Got message:", msg)
	end)

	-- Dispatch an event:
	signal:Fire("Hello world!")
	```
]=]
local Signal = {}
Signal.__index = Signal

--[=[
	Constructs a new Signal

	@return Signal
]=]
function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({
		_handlerListHead = false,
		_proxyHandler = nil,
		_yieldedThreads = nil,
	}, Signal)

	return self
end

--[=[
	Constructs a new Signal that wraps around an RBXScriptSignal.

	@param rbxScriptSignal RBXScriptSignal -- Existing RBXScriptSignal to wrap
	@return Signal

	For example:
	```lua
	local signal = Signal.Wrap(workspace.ChildAdded)
	signal:Connect(function(part) print(part.Name .. " added") end)
	Instance.new("Part").Parent = workspace
	```
]=]
function Signal.Wrap<T...>(rbxScriptSignal: RBXScriptSignal): Signal<T...>
	assert(
		typeof(rbxScriptSignal) == "RBXScriptSignal",
		"Argument #1 to Signal.Wrap must be a RBXScriptSignal got " .. typeof(rbxScriptSignal)
	)

	local signal = Signal.new()
	signal._proxyHandler = rbxScriptSignal:Connect(function(...)
		signal:Fire(...)
	end)

	return signal
end

--[=[
	Checks if the given object is a Signal.

	@param obj any -- Object to check
	@return boolean -- `true` if the object is a Signal.
]=]
function Signal.Is(obj: any): boolean
	return type(obj) == "table" and getmetatable(obj) == Signal
end

--[=[
	@param fn ConnectionFn
	@return SignalConnection

	Connects a function to the signal, which will be called anytime the signal is fired.
	```lua
	signal:Connect(function(msg, num)
		print(msg, num)
	end)

	signal:Fire("Hello", 25)
	```
]=]
function Signal:Connect(fn)
	local connection = setmetatable({
		Connected = true,
		_signal = self,
		_fn = fn,
		_next = false,
	}, Connection)

	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end

	return connection
end

--[=[
	@deprecated v1.3.0 -- Use `Signal:Once` instead.
	@param fn ConnectionFn
	@return SignalConnection
]=]
function Signal:ConnectOnce(fn)
	return self:Once(fn)
end

--[=[
	@param fn ConnectionFn
	@return SignalConnection

	Connects a function to the signal, which will be called the next time the signal fires. Once
	the connection is triggered, it will disconnect itself.
	```lua
	signal:Once(function(msg, num)
		print(msg, num)
	end)

	signal:Fire("Hello", 25)
	signal:Fire("This message will not go through", 10)
	```
]=]
function Signal:Once(fn)
	local connection
	local done = false

	connection = self:Connect(function(...)
		if done then
			return
		end

		done = true
		connection:Disconnect()
		fn(...)
	end)

	return connection
end

function Signal:GetConnections()
	local items = {}

	local item = self._handlerListHead
	while item do
		table.insert(items, item)
		item = item._next
	end

	return items
end

-- Disconnect all handlers. Since we use a linked list it suffices to clear the
-- reference to the head handler.
--[=[
	Disconnects all connections from the signal.
	```lua
	signal:DisconnectAll()
	```
]=]
function Signal:DisconnectAll()
	local item = self._handlerListHead
	while item do
		item.Connected = false
		item = item._next
	end
	self._handlerListHead = false

	local yieldedThreads = rawget(self, "_yieldedThreads")
	if yieldedThreads then
		for thread in yieldedThreads do
			if coroutine.status(thread) == "suspended" then
				warn(debug.traceback(thread, "signal disconnected yielded thread cancelled", 2))
				task.cancel(thread)
			end
		end
		table.clear(self._yieldedThreads)
	end
end

-- Signal:Fire(...) implemented by running the handler functions on the
-- coRunnerThread, and any time the resulting thread yielded without returning
-- to us, that means that it yielded to the Roblox scheduler and has been taken
-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
--[=[
	@param ... any

	Fire the signal, which will call all of the connected functions with the given arguments.
	```lua
	signal:Fire("Hello")

	-- Any number of arguments can be fired:
	signal:Fire("Hello", 32, {Test = "Test"}, true)
	```
]=]
function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item.Connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

--[=[
	@param ... any

	Same as `Fire`, but uses `task.defer` internally & doesn"t take advantage of thread reuse.
	```lua
	signal:FireDeferred("Hello")
	```
]=]
function Signal:FireDeferred(...)
	local item = self._handlerListHead
	while item do
		local conn = item
		task.defer(function(...)
			if conn.Connected then
				conn._fn(...)
			end
		end, ...)
		item = item._next
	end
end

--[=[
	@return ... any
	@yields

	Yields the current thread until the signal is fired, and returns the arguments fired from the signal.
	Yielding the current thread is not always desirable. If the desire is to only capture the next event
	fired, using `Once` might be a better solution.
	```lua
	task.spawn(function()
		local msg, num = signal:Wait()
		print(msg, num) --> "Hello", 32
	end)
	signal:Fire("Hello", 32)
	```
]=]
function Signal:Wait()
	local yieldedThreads = rawget(self, "_yieldedThreads")
	if not yieldedThreads then
		yieldedThreads = {}
		rawset(self, "_yieldedThreads", yieldedThreads)
	end

	local thread = coroutine.running()
	yieldedThreads[thread] = true

	self:Once(function(...)
		yieldedThreads[thread] = nil
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

--[=[
	Cleans up the signal.

	Technically, this is only necessary if the signal is created using
	`Signal.Wrap`. Connections should be properly GC"d once the signal
	is no longer referenced anywhere. However, it is still good practice
	to include ways to strictly clean up resources. Calling `Destroy`
	on a signal will also disconnect all connections immediately.
	```lua
	signal:Destroy()
	```
]=]
function Signal:Destroy()
	self:DisconnectAll()

	local proxyHandler = rawget(self, "_proxyHandler")
	if proxyHandler then
		proxyHandler:Disconnect()
	end
end

-- Make signal strict
setmetatable(Signal, {
	__index = function(_tb, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(_tb, key, _value)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
})

return table.freeze({
	new = Signal.new,
	Wrap = Signal.Wrap,
	Is = Signal.Is,
})
end)()
type Signal<T...> = Signal.Signal<T...>

local function inside(x: number, y: number, pX: number, pY: number, sX: number, sY: number) : boolean
	return x > pX and x < pX + sX and y > pY and y < pY + sY
end

local function insideFrame(input: Vector3, frame: Frame)
	local position = frame.AbsolutePosition
	local size = frame.AbsoluteSize

	return inside(input.X, input.Y, position.X, position.Y, size.X, size.Y)
end

local function deepCopy(t: { any }) : { any }
	local copy = {}

	for k, v in t do
		if type(v) == "table" then
			v = deepCopy(v)
		end

		copy[k] = v
	end

	return copy
end

type UIFeature<T> = {
	_trove: Trove,

	value: T,
	changed: Signal<T>,
	set: (self: UIFeature<T>, value: T) -> UIFeature<T>,
}

type UIExtendable = {
	_trove: Trove,
	instances: {
		container: Frame,
		canvas: Frame,
	},

	sectionHolder: UISectionHolder?,

	visible: boolean,
	setVisible: (self: UIExtendable, state: boolean) -> (),

	parent: (UITabList | UIIconList)?,
	child: (UITabList | UIIconList | UISectionHolder)?,

	newTabList: (self: UIExtendable) -> UITabList,
	newIconList: (self: UIExtendable) -> UIIconList,

	intoSections: (self: UIExtendable) -> UISectionHolder,
}

type UISectionHolder = {
	_trove: Trove,
	parent: UIExtendable,
	canvas: {
		left: ScrollingFrame,
		right: ScrollingFrame,
	},

	sections: {
		left: { [number]: UISection },
		right: { [number]: UISection },
	},

	newSection: (self: UISectionHolder, side: "left" | "right", label: string) -> UISection,
	_makeInstances: (self: UISectionHolder) -> (),
}

type UISection = {
	_trove: Trove,
	parent: UISectionHolder,

	instances: {
		container: Frame,
		canvas: Frame,
		label: TextLabel,
	},

	_makeInstances: (self: UISection, side: "left" | "right") -> (),
	setLabel: (self: UISection, label: string) -> (),

	newToggle: (self: UISection, flag: string) -> UIToggle,
	newSlider: (self: UISection, flag: string, min: number?, max: number?, decimals: number?) -> UISlider,
	newDropdown: (self: UISection, flag: string, multi: boolean, options: { string }, optionsCallback: any?, closeOnSelect: boolean?, dontSave: boolean?) -> UIDropdown,
	newList: (self: UISection, flag: string, size: number, options: { string }) -> UIList,
	newButton: (self: UISection, flag: string) -> UIButton,
	newTextBox: (self: UISection, flag: string) -> UITextBox,
	newLabel: (self: UISection, flag: string) -> UILabel,
	newCurveGraph: (self: UISection, flag: string) -> (),
}

local UISection = {}
UISection.__index = UISection
do
	function UISection.new(parent: UISectionHolder, side: "left" | "right", label: string) : UISection
		local self = setmetatable({}, UISection)
		self._trove = parent._trove:Extend()
		self.instances = {}
		self.parent = parent

		return UISection.into((self :: any) :: UISection, side, label)
	end

	function UISection.setLabel(self: UISection, label: string)
		assert(label, "UISection.setLabel(_, _, label) -> expected string got nil")
		assert(typeof(label) == "string", "UISection.setLabel(_, _, label) -> expected string, got " .. typeof(label))

		self.instances.label.Text = label
	end

	function UISection._makeInstances(self: UISection, side: "left" | "right")
		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		container.BorderColor3 = Color3.fromRGB(50, 50, 50)
		container.Size = UDim2.new(1, -2, 0, 22)
		self.instances.container = container

		local inline: Frame = Instance.new("Frame")
		inline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		inline.BorderSizePixel = 0
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.Parent = container

		local theme: Frame = Instance.new("Frame")
		theme.BackgroundColor3 = Color3.fromRGB(55, 175, 225)
		theme.BorderSizePixel = 0
		theme.Size = UDim2.new(1, 0, 0, 2)
		theme.Parent = inline

		local label: TextLabel = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Arial
		label.TextSize = 12
		label.TextStrokeTransparency = 0
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.new(0, 3, 0, 5)
		label.Size = UDim2.new(1, -6, 0, 11)
		label.Parent = inline
		self.instances.label = label

		local canvas: Frame = Instance.new("Frame")
		canvas.Position = UDim2.new(0, 0, 1, 0)
		canvas.Size = UDim2.new(1, 0, 1, -20)
		canvas.AnchorPoint = Vector2.new(0, 1)
		canvas.BackgroundTransparency = 1
		canvas.Parent = inline
		self.instances.canvas = canvas

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 4)
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = canvas

		container.Parent = self.parent.canvas[side]
	end

	function UISection.into(self: UISection, side: "left" | "right", label: string) : UISection
		self:_makeInstances(side)
		self:setLabel(label)
		return self
	end
end

local UISectionHolder = {}
UISectionHolder.__index = UISectionHolder
do
	function UISectionHolder.new(parent: UIExtendable) : UISectionHolder
		local self = setmetatable({}, UISectionHolder)
		self._trove = parent._trove:Extend()
		self.sections = {
			left = {},
			right = {},
		}
		self.parent = parent

		return UISectionHolder.into((self :: any) :: UISectionHolder)
	end

	function UISectionHolder.newSection(self: UISectionHolder, side: "left" | "right", label: string) : UISection
		assert(side, "UIExtendable.newSection(_, side) : _ -> expected string got nil")
		assert(typeof(side) == "string", "UIExtendable.newSection(_, side) : _ -> expected string, got " .. typeof(side))
		assert(side == "left" or side == "right", "UIExtendable.newSection(_, side) : _ -> expected { \"Left\" | \"Right\" }, got \"" .. side .. "\"")

		return UISection.new(self, side, label)
	end

	function UISectionHolder._makeInstances(self: UISectionHolder)
		assert(self.sections, "UIExtendable._makeSectionInstances(_) -> internal failure")

		local leftCanvas: ScrollingFrame = Instance.new("ScrollingFrame")
		leftCanvas.BackgroundTransparency = 1
		leftCanvas.Position = UDim2.new(0, 5, 0, 5)
		leftCanvas.AutomaticCanvasSize = Enum.AutomaticSize.Y
		leftCanvas.Size = UDim2.new(0.5, -8, 1, -10)
		leftCanvas.BorderSizePixel = 0
		leftCanvas.CanvasSize = UDim2.new(0, 0)
		leftCanvas.ScrollBarThickness = 1

		local uiLayout = Instance.new("UIListLayout")
		uiLayout.Padding = UDim.new(0, 7)
		uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uiLayout.Parent = leftCanvas

		local uiPadding = Instance.new("UIPadding")
		uiPadding.PaddingTop = UDim.new(0, 1)
		uiPadding.PaddingBottom = UDim.new(0, 1)
		uiPadding.Parent = leftCanvas

		local rightCanvas: ScrollingFrame = Instance.new("ScrollingFrame")
		rightCanvas.BackgroundTransparency = 1
		rightCanvas.Position = UDim2.new(0.5, 3, 0, 5)
		rightCanvas.AutomaticCanvasSize = Enum.AutomaticSize.Y
		rightCanvas.Size = UDim2.new(0.5, -8, 1, -10)
		rightCanvas.BorderSizePixel = 0
		rightCanvas.CanvasSize = UDim2.new(0, 0)
		rightCanvas.ScrollBarThickness = 1

		local uiLayout = Instance.new("UIListLayout")
		uiLayout.Padding = UDim.new(0, 7)
		uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		uiLayout.Parent = rightCanvas

		local uiPadding = Instance.new("UIPadding")
		uiPadding.PaddingTop = UDim.new(0, 1)
		uiPadding.PaddingBottom = UDim.new(0, 1)
		uiPadding.Parent = rightCanvas

		self.canvas = {
			left = leftCanvas,
			right = rightCanvas,
		}

		leftCanvas.Parent = self.parent.instances.canvas
		rightCanvas.Parent = self.parent.instances.canvas
	end

	function UISectionHolder.into(self: UISectionHolder) : UISectionHolder
		self:_makeInstances()
		return self
	end
end

local UIExtendable = {}
UIExtendable.__index = UIExtendable
do
	function UIExtendable.new() : UIExtendable
		local self = setmetatable({}, UIExtendable)
		self.instances = {}
		self.visible = false

		return UIExtendable.into((self :: any) :: UIExtendable)
	end

	function UIExtendable.into(self: UIExtendable) : UIExtendable
		return self
	end

	function UIExtendable.intoSections(self: UIExtendable) : UISectionHolder
		local child = UISectionHolder.new(self)
		self.child = child

		return child
	end
end

type UIColorpickerMenu = {
	_trove: Trove,

	instances: {
		container: Frame,
		huePicker: TextButton,
		huePosition: Frame,
		chromePicker: TextButton,
		chromePosition: Frame,
		saturationGradient: UIGradient,
		alphaPicker: TextButton,
		alphaPosition: Frame,
	},

	dragging: boolean,

	feature: UIColorpicker?,

	attach: (self: UIColorpickerMenu, feature: UIColorpicker, base: UIBase & UIExtendable) -> (),
	detach: (self: UIColorpickerMenu, base: UIBase) -> (),

	_makeInstances: (self: UIColorpickerMenu) -> (),
	Destroy: (self: UIColorpickerMenu) -> (),
}

local UIColorpickerMenu = {}
UIColorpickerMenu.__index = UIColorpickerMenu
do
	function UIColorpickerMenu.new(base: UIExtendable)
		local self = setmetatable({}, UIColorpickerMenu)
		self._trove = base._trove:Extend()

		self.instances = {}
		self.ref = base
		self.options = {}

		return UIColorpickerMenu.into((self :: any) :: UIColorpickerMenu)
	end

	function UIColorpickerMenu.attach(self: UIColorpickerMenu, colorpicker: UIColorpicker, base: UIBase & UIExtendable)
		if base.activeMenu ~= "none" then
			self:detach(base :: any) --> Why, Luau?
		end

		self.feature = colorpicker

		if colorpicker.hasAlpha then
			self.instances.alphaPicker.Visible = true
			self.instances.container.Size = UDim2.new(0, 246, 0, 260)
		else
			self.instances.alphaPicker.Visible = false
			self.instances.container.Size = UDim2.new(0, 246, 0, 236)
		end

		self._trove:Connect(UserInputService.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local inputX, inputY = input.Position.X, input.Position.Y

				local container = self.instances.container
				local position, size = container.AbsolutePosition, container.AbsoluteSize

				if inside(inputX, inputY, position.X, position.Y, size.X, size.Y) then
					return
				end

				local outline = colorpicker.instances.container
				local absPosition, absSize = outline.AbsolutePosition, outline.AbsoluteSize

				if not inside(inputX, inputY, absPosition.X, absPosition.Y, absSize.X, absSize.Y) then
					self:detach(base)

					colorpicker.open = false
				end
			end
		end)

		self._trove:Connect(colorpicker.changed :: any, function(state: ColorpickerState)
			local h, s, v = state.rgb:ToHSV()

			self.instances.saturationGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
			})

			self.instances.huePosition.Position = UDim2.new(0.5, -4, 0, math.clamp(200 - (h * 200), 0, 198))
			self.instances.chromePosition.Position = UDim2.new(0, math.clamp((s * 200), 0, 196), 0, math.clamp(200 - (v * 200), 0, 196))

			self.instances.alphaPosition.Position = UDim2.new(0, math.clamp(state.alpha * 224, 0, 222), 0.5, -4)
		end)

		--> update immediately
		do
			local h, s, v = colorpicker.value.rgb:ToHSV()

			self.instances.saturationGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
			})

			self.instances.huePosition.Position = UDim2.new(0.5, -4, 0, math.clamp(200 - (h * 200), 0, 198))
			self.instances.chromePosition.Position = UDim2.new(0, math.clamp((s * 200), 0, 196), 0, math.clamp(200 - (v * 200), 0, 196))

			self.instances.alphaPosition.Position = UDim2.new(0, math.clamp(colorpicker.value.alpha * 224, 0, 222), 0.5, -4)
		end

		base:makeDraggable(self.instances.huePicker, self._trove, function(input: InputObject)
			local inline = self.instances.huePicker
			local position = input.Position

			local percent = 1 - math.clamp((position.Y - inline.AbsolutePosition.Y) / inline.AbsoluteSize.Y, 0, 1)

			local h, s, v = colorpicker.value.rgb:ToHSV()
			colorpicker:set({ rgb = Color3.fromHSV(percent, s, v), alpha = colorpicker.value.alpha })

			self.instances.huePosition.Position = UDim2.new(0.5, -4, 0, math.clamp(200 - (percent * 200), 0, 198))
		end)

		base:makeDraggable(self.instances.chromePicker, self._trove, function(input: InputObject)
			local inline = self.instances.chromePicker
			local position = input.Position

			local percentX = math.clamp((position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X, 0, 1)
			local percentY = math.clamp((position.Y - inline.AbsolutePosition.Y) / inline.AbsoluteSize.Y, 0, 1)

			local h, s, v = colorpicker.value.rgb:ToHSV()

			colorpicker:set({ rgb = Color3.fromHSV(h, percentX, 1 - percentY), alpha = colorpicker.value.alpha })

			self.instances.chromePosition.Position = UDim2.new(0, math.clamp((percentX * 200), 0, 196), 0, math.clamp(200 - ((1 - percentY) * 200), 0, 196))
		end)

		if colorpicker.hasAlpha then
			base:makeDraggable(self.instances.alphaPicker, self._trove, function(input: InputObject)
				local inline = self.instances.alphaPicker
				local position = input.Position

				local percent = math.clamp((position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X, 0, 1)

				colorpicker:set({ rgb = colorpicker.value.rgb, alpha = percent })
			end)
		end

		self.instances.container.Position = UDim2.new(0, colorpicker.instances.container.AbsolutePosition.X, 0, colorpicker.instances.container.AbsolutePosition.Y + 74)

		self.instances.container.Parent = base.instances.gui
		base.activeMenu = "color"
	end

	function UIColorpickerMenu.detach(self: UIColorpickerMenu, base: UIBase)
		if not self.feature then
			return
		end

		self.feature.open = false
		self.feature = nil

		base.activeMenu = "none"
		self.instances.container.Parent = nil
		self._trove:Clean()
	end

	function UIColorpickerMenu._makeInstances(self: UIColorpickerMenu)
		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(55, 175, 225)
		container.BorderSizePixel = 1
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.Size = UDim2.new(0, 246, 0, 236)
		container.ZIndex = 2
		self.instances.container = container

		local background: Frame = Instance.new("Frame")
		background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		background.BorderSizePixel = 0
		background.Position = UDim2.new(0, 1, 0, 1)
		background.Size = UDim2.new(1, -2, 1, -2)
		background.ZIndex = 2
		background.Parent = container

		local title: TextLabel = Instance.new("TextLabel")
		title.Font = Enum.Font.Arial
		title.Position = UDim2.new(0, 4, 0, 4)
		title.Size = UDim2.new(1, -8, 0, 11)
		title.ZIndex = 2
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextStrokeTransparency = 0
		title.TextSize = 12
		title.Text = "Colorpicker"
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = background

		local canvas: Frame = Instance.new("Frame")
		canvas.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		canvas.BorderColor3 = Color3.fromRGB(50, 50, 50)
		canvas.Position = UDim2.new(0, 5, 0, 19)
		canvas.Size = UDim2.new(1, -10, 1, -24)
		canvas.ZIndex = 2
		canvas.Parent = background

		local inline: Frame = Instance.new("Frame")
		inline.ZIndex = 2
		inline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.BorderSizePixel = 0
		inline.Parent = canvas

		local huePicker: TextButton = Instance.new("TextButton")
		huePicker.Text = ""
		huePicker.AutoButtonColor = false
		huePicker.BorderSizePixel = 0
		huePicker.Position = UDim2.new(0, 208, 0, 4)
		huePicker.Size = UDim2.new(0, 20, 0, 200)
		huePicker.ZIndex = 2
		huePicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		huePicker.Parent = inline
		self.instances.huePicker = huePicker

		local hueGradient: UIGradient = Instance.new("UIGradient")
		hueGradient.Rotation = 90
		hueGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(0.335, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
		hueGradient.Parent = huePicker

		local huePosition: Frame = Instance.new("Frame")
		huePosition.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		huePosition.BorderColor3 = Color3.fromRGB(0, 0, 0)
		huePosition.Position = UDim2.new(0.5, -4, 0, 0)
		huePosition.Size = UDim2.new(0, 8, 0, 2)
		huePosition.ZIndex = 2
		huePosition.Parent = huePicker
		self.instances.huePosition = huePosition

		local chromePicker: TextButton = Instance.new("TextButton")
		chromePicker.Text = ""
		chromePicker.AutoButtonColor = false
		chromePicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		chromePicker.BorderSizePixel = 0
		chromePicker.Position = UDim2.new(0, 4, 0, 4)
		chromePicker.Size = UDim2.new(0, 200, 0, 200)
		chromePicker.ZIndex = 2
		chromePicker.Parent = inline
		self.instances.chromePicker = chromePicker

		local saturation: Frame = Instance.new("Frame")
		saturation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		saturation.BorderSizePixel = 0
		saturation.Size = UDim2.new(1, 0, 1, 0)
		saturation.ZIndex = 2
		saturation.Parent = chromePicker

		local saturationGradient: UIGradient = Instance.new("UIGradient")
		saturationGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
		saturationGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		saturationGradient.Parent = saturation
		self.instances.saturationGradient = saturationGradient

		local brightness: Frame = Instance.new("Frame")
		brightness.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		brightness.BorderSizePixel = 0
		brightness.Size = UDim2.new(1, 0, 1, 0)
		brightness.ZIndex = 2
		brightness.Parent = chromePicker

		local brightnessGradient: UIGradient = Instance.new("UIGradient")
		brightnessGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		brightnessGradient.Rotation = 90
		brightnessGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		brightnessGradient.Parent = brightness

		local chromePosition: Frame = Instance.new("Frame")
		chromePosition.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		chromePosition.BorderColor3 = Color3.fromRGB(0, 0, 0)
		chromePosition.Position = UDim2.new(0, 0, 0, 0)
		chromePosition.Size = UDim2.new(0, 4, 0, 4)
		chromePosition.ZIndex = 2
		chromePosition.Parent = chromePicker
		self.instances.chromePosition = chromePosition

		local alphaPicker: TextButton = Instance.new("TextButton")
		alphaPicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		alphaPicker.BorderSizePixel = 0
		alphaPicker.Position = UDim2.new(0, 4, 0, 208)
		alphaPicker.Size = UDim2.new(0, 224, 0, 20)
		alphaPicker.ZIndex = 2
		alphaPicker.Text = ""
		alphaPicker.AutoButtonColor = false
		alphaPicker.Parent = inline
		self.instances.alphaPicker = alphaPicker

		local alphaGradient: UIGradient = Instance.new("UIGradient")
		alphaGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		alphaGradient.Parent = alphaPicker

		local alphaPosition: Frame = Instance.new("Frame")
		alphaPosition.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		alphaPosition.BorderColor3 = Color3.fromRGB(0, 0, 0)
		alphaPosition.Position = UDim2.new(0, 0, 0.5, -4)
		alphaPosition.Size = UDim2.new(0, 2, 0, 8)
		alphaPosition.ZIndex = 2
		alphaPosition.Parent = alphaPicker
		self.instances.alphaPosition = alphaPosition
	end

	function UIColorpickerMenu.into(self: UIColorpickerMenu) : UIColorpickerMenu
		self:_makeInstances()
		return self
	end

	function UIColorpickerMenu.Destroy(self: UIColorpickerMenu)

	end
end

type UIDropdownMenu = {
	_trove: Trove,

	instances: {
		container: Frame,
		layout: ScrollingFrame,
		buttons: { TextButton },
	},

	feature: UIDropdown?,

	attach: (self: UIDropdownMenu, feature: UIDropdown, base: UIBase) -> (),
	detach: (self: UIDropdownMenu, base: UIBase) -> (),

	options: { [string]: Trove },
	add: (self: UIDropdownMenu, option: string) -> Trove,

	resize: (self: UIDropdownMenu) -> (),

	_makeInstances: (self: UIDropdownMenu) -> (),
	Destroy: (self: UIDropdownMenu) -> (),
}

local UIDropdownMenu = {}
UIDropdownMenu.__index = UIDropdownMenu
do
	function UIDropdownMenu.new(base: UIExtendable)
		local self = setmetatable({}, UIDropdownMenu)
		self._trove = base._trove:Extend()

		self.instances = {}
		self.ref = base
		self.options = {}

		return UIDropdownMenu.into((self :: any) :: UIDropdownMenu)
	end

	function UIDropdownMenu.resize(self: UIDropdownMenu)
		assert(self.feature, "")
		self.instances.container.Size = UDim2.new(1, 0, 0, math.min(6, #self.feature.options) * 17 + 1)
	end

	function UIDropdownMenu.add(self: UIDropdownMenu, option: string) : Trove
		assert(self.feature, "")
		local trove = self._trove:Extend()

		local outline: TextButton = Instance.new("TextButton")
		outline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		outline.BorderColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.Size = UDim2.new(1, 0, 0, 16)
		outline.AutoButtonColor = false
		outline.Text = ""
		outline.ZIndex = 2

		local label: TextLabel = Instance.new("TextLabel")
		label.Font = Enum.Font.Arial
		label.TextSize = 12
		label.TextStrokeTransparency = 0
		label.Position = UDim2.new(0, 4, 0, 3)
		label.Size = UDim2.new(1, -8, 0, 11)
		label.Text = option
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 2
		label.Parent = outline

		local value = self.feature.value
		if typeof(value) == "table" and value[option] or option == value then
			label.TextColor3 = Color3.fromRGB(55, 175, 225)
		else
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		outline.Parent = self.instances.layout

		trove:Connect(outline.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local value = self.feature.value

				if typeof(value) == "table" then
					value[option] = not value[option]

					self.feature:set(value)
				else
					self.feature:set(option)
				end

                if self.feature.closeOnSelect then
                    self.feature:setOpen(false, self.ref)
                    self.ref.menus.dropdown:detach(self.ref :: any)
                end
			end
		end)

		self:resize()
		trove:Add(outline)
		return trove
	end

	function UIDropdownMenu.attach(self: UIDropdownMenu, dropdown: UIDropdown, base: UIBase)
		if base.activeMenu ~= "none" then
			self:detach(base :: any) --> Why, Luau?
		end

		self.feature = dropdown

		for _, option in dropdown.options do
			self.options[option] = self:add(option)
		end

		self._trove:Connect(dropdown.onOptionAdded :: any, function(option: string)
			self.options[option] = self:add(option)
		end)

		self._trove:Connect(dropdown.onOptionRemoved :: any, function(option: string)
			self._trove:Remove(self.options[option])
			self.options[option] = nil

			self:resize()
		end)

		self._trove:Connect(dropdown.changed :: any, function(value: { [string]: boolean } | string?)
			for _, outline in self.instances.layout:GetChildren() do
				if outline:IsA("UIListLayout") then
					continue
				end

				local label = outline:FindFirstChildOfClass("TextLabel")
				assert(label, "internal error")

				if typeof(value) == "table" and value[label.Text] or label.Text == value then
					label.TextColor3 = Color3.fromRGB(55, 175, 225)
				else
					label.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end)

		self._trove:Connect(UserInputService.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local inputX, inputY = input.Position.X, input.Position.Y

				local container = self.instances.container
				local position, size = container.AbsolutePosition, container.AbsoluteSize

				if inside(inputX, inputY, position.X, position.Y, size.X, size.Y) then
					return
				end

				local outline = dropdown.instances.outline
				local absPosition, absSize = outline.AbsolutePosition, outline.AbsoluteSize

				if not inside(inputX, inputY, absPosition.X, absPosition.Y, absSize.X, absSize.Y) then
					self:detach(base :: any)

					dropdown:setOpen(false, base)
				end
			end
		end)

		self:resize()

		self.instances.container.Position = UDim2.new(0, dropdown.instances.outline.AbsolutePosition.X + 1, 0, dropdown.instances.outline.AbsolutePosition.Y + 80)
		self.instances.container.Size = UDim2.new(0, dropdown.instances.outline.AbsoluteSize.X, 0, self.instances.container.Size.Y.Offset)
		self.instances.container.Parent = base.instances.gui
		base.activeMenu = "dropdown"
	end

	function UIDropdownMenu.detach(self: UIDropdownMenu, base: UIBase)
		assert(self.feature, "?")

		self.feature:setOpen(false, base)
		self.feature = nil

		base.activeMenu = "none"
		self.instances.container.Parent = nil
		self._trove:Clean()
		self.options = {}
	end

	function UIDropdownMenu._makeInstances(self: UIDropdownMenu)
		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		container.BorderSizePixel = 1
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.Position = UDim2.new(0, 0, 1, 3)
		container.Size = UDim2.new(1, 0, 0, 0)
		container.ZIndex = 2
		self.instances.container = container

		local layout: ScrollingFrame = Instance.new("ScrollingFrame")
		layout.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		layout.BorderSizePixel = 0
		layout.Position = UDim2.new(0, 1, 0, 1)
		layout.Size = UDim2.new(1, -2, 1, -2)
		layout.AutomaticCanvasSize = Enum.AutomaticSize.Y
		layout.CanvasSize = UDim2.new(0, 0, 0, 0)
		layout.ScrollBarImageColor3 = Color3.fromRGB(55, 175, 225)
		layout.ScrollingDirection = Enum.ScrollingDirection.Y
		layout.ScrollBarThickness = 4
		layout.TopImage = "rbxasset://textures/AvatarEditorImages/LightPixel.png"
		layout.MidImage = "rbxasset://textures/AvatarEditorImages/LightPixel.png"
		layout.BottomImage = "rbxasset://textures/AvatarEditorImages/LightPixel.png"
		layout.ZIndex = 2
		layout.Parent = container
		self.instances.layout = layout

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 1)
		listLayout.Parent = layout
	end

	function UIDropdownMenu.into(self: UIDropdownMenu) : UIDropdownMenu
		self:_makeInstances()
		return self
	end

	function UIDropdownMenu.Destroy(self: UIDropdownMenu)

	end
end

type UIBase = UIExtendable & {
	instances: {
		gui: ScreenGui,
		label: TextLabel,
		drag: TextButton,
		resize: TextButton,
		open: TextButton,
	},

	features: { [string]: UIFeature<any> },

	dragging: boolean,
	resizing: boolean,
	keybind: Enum.KeyCode,
	binding: UIFeature<KeybindState>?,

	visibilityChanged: Signal<boolean>,

	activeMenu: "none" | "dropdown" | "color",

	menus: {
		dropdown: UIDropdownMenu,
		colorpicker: UIColorpickerMenu,
	},

	makeDraggable: (self: UIBase, guiObject: GuiObject, trove: Trove, callback: (input: InputObject) -> ()) -> (),

	encodeJSON: (self: UIBase) -> string,

	_makeInstances: (self: UIBase) -> (),

	setLabel: (self: UIBase, label: string) -> UIBase,
	setKeybind: (self: UIBase, keybind: Enum.KeyCode) -> UIBase,
	Finish: (self: UIBase) -> (),
	Destroy: (self: UIBase) -> (),
}

type UIIconList = {
	_trove: Trove,
	instances: {
		container: Frame,
		canvas: Frame,
		layout: Frame,
	},
	children: { [number]: UIIcon },
	parent: UIExtendable,

	_makeInstances: (self: UIIconList) -> (),
	newIcon: (self: UIIconList, image: string) -> UIIcon,
	_makeIconInstances: (self: UIIconList, tab: UIIcon) -> (),
	_resize: (self: UIIconList) -> (),
}

type UIIcon = UIExtendable & {
	instances: {
		button: TextButton,
		image: ImageLabel,
	},

	setVisible: (self: UIIcon, state: boolean) -> (),
}

local UIIconList = {}
UIIconList.__index = UIIconList
do
	function UIIconList.new(parent: UIExtendable) : UIIconList
		assert(parent, "TabList.new(parent) : _ -> expected UIExtendable, got nil")

		local self = setmetatable({}, UIIconList)
		self._trove = parent._trove:Extend()
		self.instances = {}
		self.children = {}
		self.parent = parent

		return UIIconList.into((self :: any) :: UIIconList)
	end

	function UIIconList.newIcon(self: UIIconList, image: string)
		assert(image, "UIIconList.newIcon(_, image) : _ -> expected string got nil")
		assert(typeof(image) == "string", "UIIconList.newIcon(_, image) : _ -> expected string, got " .. typeof(image))

		local tab: UIExtendable = UIExtendable.new()
		tab._trove = self._trove:Extend()

		local tab: UIIcon = tab :: UIIcon
		tab.setVisible = UIIconList.setVisible
		tab.parent = self
		table.insert(self.children, tab)

		self:_makeIconInstances(tab)
		tab.instances.image.Image = image

		if #self.children == 1 then
			tab:setVisible(true)
		end

		self._trove:Connect(tab.instances.button.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				tab:setVisible(true)
			end
		end)

		self:_resize()

		return tab
	end

	function UIIconList.setVisible(self: UIExtendable, state: boolean)
		return UIIconList.setIconVisible(self :: UIIcon, state)
	end

	function UIIconList.setIconVisible(self: UIIcon, state: boolean)
		assert(typeof(state) == "boolean", "UIIconList.setVisible(_, state: boolean) -> expected boolean, got " .. typeof(state))
		assert(state, "UIIconList.setVisible(_, state: boolean) -> unused variable")

		if self.visible == state then
			return
		end

		self.visible = state

		assert(self.parent, "UIIconList.setIconVisible(_, _) -> internal failure")

		for _, tab in self.parent.children :: { [number]: UIIcon } do
			local instances = tab.instances
			instances.image.ImageColor3 = Color3.fromRGB(150, 150, 150)
			instances.canvas.Visible = false

			tab.visible = false
		end

		local instances = self.instances
		instances.image.ImageColor3 = Color3.fromRGB(255, 255, 255)
		instances.canvas.Visible = true
	end

	function UIIconList._makeIconInstances(self: UIIconList, tab: UIIcon)
		local button: TextButton = Instance.new("TextButton")
		button.Size = UDim2.new(0, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		tab.instances.button = button

		local image: ImageLabel = Instance.new("ImageLabel")
		image.Position = UDim2.new(0.5, 0, 0.5, 0)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Size = UDim2.new(0, 48, 1, 0)
		image.BackgroundTransparency = 1
		image.ImageColor3 = Color3.fromRGB(150, 150, 150)
		image.Parent = button
		tab.instances.image = image

		local canvas: Frame = Instance.new("Frame")
		canvas.Size = UDim2.new(1, 0, 1, 0)
		canvas.BackgroundTransparency = 1
		canvas.Visible = false
		canvas.Parent = self.instances.canvas
		tab.instances.canvas = canvas
		tab.instances.container = canvas

		button.Parent = self.instances.layout
	end

	function UIIconList._makeInstances(self: UIIconList)
		local container: Frame = Instance.new("Frame")
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		container.Size = UDim2.new(1, -10, 0, 50)
		container.Position = UDim2.new(0, 5, 0, 5)

		local layout: Frame = Instance.new("Frame")
		layout.BorderSizePixel = 0
		layout.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		layout.Size = UDim2.new(1, -2, 1, -2)
		layout.Position = UDim2.new(0, 1, 0, 1)
		layout.Parent = container
		self.instances.layout = layout

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Horizontal
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = layout

		local canvas: Frame = Instance.new("Frame")
		canvas.BackgroundTransparency = 1
		canvas.Position = UDim2.new(0, 0, 0, 55)
		canvas.Size = UDim2.new(1, 0, 1, -55)
		self.instances.canvas = canvas

		container.Parent = self.parent.instances.canvas
		canvas.Parent = self.parent.instances.canvas
	end

	function UIIconList._resize(self: UIIconList)
		local layout: Frame = self.instances.layout
		local cnt: number = #self.children

		local totalSize: number = layout.AbsoluteSize.X
		local size: number = totalSize / cnt

		for _, tab in self.children do
			tab.instances.button.Size = UDim2.new(0, size, 1, 0)
		end

		local last: UIIcon = self.children[#self.children]
		local button: TextButton = last.instances.button

		local curr: number = button.AbsolutePosition.X + button.AbsoluteSize.X
		local expected: number = layout.AbsolutePosition.X + layout.AbsoluteSize.X
		local diff: number = expected - curr

		if diff ~= 0 then
			button.Size += UDim2.new(0, diff, 0, 0)
		end
	end

	function UIIconList.into(self: UIIconList) : UIIconList
		self:_makeInstances()
		return self
	end
end

type UITabList = {
	_trove: Trove,
	instances: {
		container: Frame,
		canvas: Frame,
		layout: Frame,
	},
	children: { [number]: UITab },
	parent: UIExtendable,

	_makeInstances: (self: UITabList) -> (),
	newTab: (self: UITabList, label: string) -> UITab,
	_makeTabInstances: (self: UITabList, tab: UITab) -> (),
	_resize: (self: UITabList) -> (),
}

type UITab = UIExtendable & {
	instances: {
		inline: Frame,
		outline: Frame,
		button: TextButton,
		cover: Frame,
	},

	setVisible: (self: UITab, state: boolean) -> (),
}

local UITabList = {}
UITabList.__index = UITabList
do
	function UITabList.new(parent: UIExtendable) : UITabList
		assert(parent, "TabList.new(parent) : _ -> expected UIExtendable, got nil")

		local self = setmetatable({}, UITabList)
		self._trove = parent._trove:Extend()
		self.instances = {}
		self.children = {}
		self.parent = parent

		return UITabList.into((self :: any) :: UITabList)
	end

	function UITabList.newTab(self: UITabList, label: string) : UITab
		assert(label, "TabList.newTab(_, label) : _ -> expected string got nil")
		assert(typeof(label) == "string", "TabList.newTab(_, label) : _ -> expected string, got " .. typeof(label))

		local tab: UIExtendable = UIExtendable.new()
		tab._trove = self._trove:Extend()

		local tab: UITab = tab :: UITab
		tab.setVisible = UITabList.setVisible
		tab.parent = self
		table.insert(self.children, tab)

		self:_makeTabInstances(tab)
		tab.instances.button.Text = label

		if #self.children == 1 then
			tab:setVisible(true)
		end

		self._trove:Connect(tab.instances.button.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				tab:setVisible(true)
			end
		end)

		self:_resize()

		return tab
	end

	function UIExtendable.newTabList(self: UIExtendable) : UITabList
		assert(self.sectionHolder == nil, "UIExtendable.newIconList(_) : _ -> expected sections to be nil")
		assert(self.child == nil, "UIExtendable.newTabList(_) : _ -> expected child to be nil")

		local tabList: UITabList = UITabList.new(self)
		self.child = tabList

		return tabList
	end

	function UIExtendable.newIconList(self: UIExtendable) : UIIconList
		assert(self.sectionHolder == nil, "UIExtendable.newIconList(_) : _ -> expected sections to be nil")
		assert(self.child == nil, "UIExtendable.newIconList(_) : _ -> expected child to be nil")

		local iconList: UIIconList = UIIconList.new(self)
		self.child = iconList

		return iconList
	end

	function UITabList.setVisible(self: UIExtendable, state: boolean)
		return UITabList.setTabVisible(self :: UITab, state)
	end

	function UITabList.setTabVisible(self: UITab, state: boolean)
		assert(typeof(state) == "boolean", "UIExtendable.setVisible(_, state: boolean) -> expected boolean, got " .. typeof(state))
		assert(state, "UIExtendable.setVisible(_, state: boolean) -> unused variable")

		if self.visible == state then
			return
		end

		self.visible = state

		assert(self.parent, "UITabList.setTabVisible(_, _) -> internal failure")

		for _, tab in self.parent.children :: { [number]: UITab } do
			local instances = tab.instances
			instances.inline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			instances.cover.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			instances.cover.Size = UDim2.new(1, 0, 0, 1)
			instances.canvas.Visible = false

			tab.visible = false
		end

		local instances = self.instances
		instances.inline.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		instances.cover.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		instances.cover.Size = UDim2.new(1, 0, 0, 2)
		instances.canvas.Visible = true
	end

	function UITabList._makeTabInstances(self: UITabList, tab: UITab)
		local outline: Frame = Instance.new("Frame")
		outline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		outline.BorderSizePixel = 0
		outline.Size = UDim2.new(0, 0, 1, 0)
		tab.instances.outline = outline

		local inline: Frame = Instance.new("Frame")
		inline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		inline.BorderColor3 = Color3.fromRGB(50, 50, 50)
		inline.Position = UDim2.new(0, 2, 0, 2)
		inline.Size = UDim2.new(1, -4, 1, -3)
		inline.Parent = outline
		tab.instances.inline = inline

		local cover: Frame = Instance.new("Frame")
		cover.BorderSizePixel = 0
		cover.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		cover.Position = UDim2.new(0, 0, 1, 0)
		cover.Size = UDim2.new(1, 0, 0, 1)
		cover.Parent = inline
		tab.instances.cover = cover

		local button: TextButton = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.Font = Enum.Font.Arial
		button.TextSize = 12
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Size = UDim2.new(1, 0, 1, 0)
		button.TextStrokeTransparency = 0
		button.Parent = inline
		tab.instances.button = button

		local canvas: Frame = Instance.new("Frame")
		canvas.Size = UDim2.new(1, 0, 1, 0)
		canvas.BackgroundTransparency = 1
		canvas.Visible = false
		canvas.Parent = self.instances.canvas
		tab.instances.canvas = canvas
		tab.instances.container = canvas

		outline.Parent = self.instances.layout
	end

	function UITabList._resize(self: UITabList)
		local layout: Frame = self.instances.layout
		local cnt: number = #self.children

		local totalSize: number = layout.AbsoluteSize.X - (cnt - 1) * 4
		local size: number = totalSize / cnt

		for _, tab in self.children do
			tab.instances.outline.Size = UDim2.new(0, size, 1, 0)
		end

		local last: UITab = self.children[#self.children]
		local outline: Frame = last.instances.outline

		local curr: number = outline.AbsolutePosition.X + outline.AbsoluteSize.X
		local expected: number = layout.AbsolutePosition.X + layout.AbsoluteSize.X
		local diff: number = expected - curr

		if diff ~= 0 then
			outline.Size += UDim2.new(0, diff, 0, 0)
		end
	end

	function UITabList._makeInstances(self: UITabList)
		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.BorderSizePixel = 1
		container.Position = UDim2.new(0, 5, 0, 26)
		container.Size = UDim2.new(1, -10, 1, -31)
		self.instances.container = container

		local canvas: Frame = Instance.new("Frame")
		canvas.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		canvas.BorderSizePixel = 0
		canvas.Position = UDim2.new(0, 1, 0, 1)
		canvas.Size = UDim2.new(1, -2, 1, -2)
		canvas.Parent = container
		self.instances.canvas = canvas

		local layout: Frame = Instance.new("Frame")
		layout.BackgroundTransparency = 1
		layout.Position = UDim2.new(0, -1, 0, -21)
		layout.Size = UDim2.new(1, 2, 0, 21)
		layout.Parent = container
		self.instances.layout = layout

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 4)
		listLayout.FillDirection = Enum.FillDirection.Horizontal
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = layout

		container.Parent = self.parent.instances.canvas
	end

	function UITabList.into(self: UITabList) : UITabList
		self:_makeInstances()
		self.parent.child = self
		return self
	end
end

local UIBase = {}
UIBase.__index = UIBase
do
	function UIBase.new() : UIBase
		local self = setmetatable({}, UIBase)
		self._trove = Trove.new()

		self.refs = {}
		self.instances = {}
		self.features = {}

		self.visible = true
		self.dragging = false
		self.keybind = Enum.KeyCode.RightShift

		self.activeMenu = "none"

		self.visibilityChanged = self._trove:Add(Signal.new())

		return UIBase.into((self :: any) :: UIBase)
	end

	function UIBase.setLabel(self: UIBase, label: string) : UIBase
		assert(label, "UIBase.setLabel(_, label) : _ -> expected string, got nil")
		assert(typeof(label) == "string", "UIBase.setLabel(_, label) : _ -> expected string, got " .. typeof(label))

		self.instances.label.Text = label
		return self
	end

	function UIBase.setKeybind(self: UIBase, keybind: Enum.KeyCode) : UIBase
		assert(keybind, "UIBase.setKeybind(_, keybind) : _ -> expected Enum.KeyCode, got nil")
		assert(typeof(keybind) == "EnumItem", "UIBase.setKeybind(_, keybind) : _ -> expected Enum.KeyCode, got " .. typeof(keybind))

		self.keybind = keybind
		return self
	end

	function UIBase.setVisible(self: UIBase, state: boolean)
		assert(typeof(state) == "boolean", "UIBase.setVisible(_, state: boolean) -> expected boolean, got " .. typeof(state))

		if self.visible == state then
			return
		end

		self.visible = state
		self.instances.container.Visible = self.visible

		self.visibilityChanged:Fire(self.visible)
	end

	function UIBase.makeDraggable(self: UIBase, guiObject: GuiObject, trove: Trove, callback: (input: InputObject) -> ())
		local dragInput: InputObject?
		local dragging: boolean = false

		local onMouseMove = function(input: InputObject)
			if dragging and input == dragInput then
				callback(input)
			end
		end

		local connection = self._trove:Connect(UserInputService.InputChanged, onMouseMove)

		trove:Connect(self.visibilityChanged :: any, function(state: boolean)
			if not state then
				dragging = false
				trove:Remove(connection)
				return
			end

			connection = trove:Connect(UserInputService.InputChanged, onMouseMove)
		end)

		trove:Connect(guiObject.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragInput = input

				onMouseMove(input)

				local onChanged
				onChanged = self._trove:Connect(input.Changed, function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						trove:Remove(onChanged)
						dragInput = nil
					end
				end)
			end
		end)

		trove:Connect(guiObject.InputChanged, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
	end

	function UIBase._makeInstances(self: UIBase)
		local screenGui: ScreenGui = Instance.new("ScreenGui")
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.ScreenInsets = Enum.ScreenInsets.None
		screenGui.DisplayOrder = 100
		self.instances.gui = screenGui

		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(55, 175, 225)
		container.BorderSizePixel = 1
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.AnchorPoint = Vector2.new(0, 0)
		container.Position = UDim2.new(0.5, -500 / 2, 0.5, -350 / 2)
		container.Size = UDim2.new(0, 500, 0, 350)
		container.Parent = screenGui
		self.instances.container = container

		local background: Frame = Instance.new("Frame")
		background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		background.Position = UDim2.new(0, 1, 0, 1)
		background.Size = UDim2.new(1, -2, 1, -2)
		background.BorderSizePixel = 0
		background.Parent = container

		local outer: Frame = Instance.new("Frame")
		outer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		outer.Position = UDim2.new(0, 5 , 0, 19)
		outer.Size = UDim2.new(1, -10, 1, -24)
		outer.BorderColor3 = Color3.fromRGB(50, 50, 50)
		outer.Parent = background

		local canvas: Frame = Instance.new("Frame")
		canvas.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		canvas.Position = UDim2.new(0, 1, 0, 1)
		canvas.Size = UDim2.new(1, -2, 1, -2)
		canvas.BorderSizePixel = 0
		canvas.Parent = outer
		self.instances.canvas = canvas

		local title: TextLabel = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -8, 0, 11)
		title.Position = UDim2.new(0, 4, 0, 4)
		title.Font = Enum.Font.Arial
		title.TextSize = 12
		title.TextStrokeTransparency = 0
		title.BackgroundTransparency = 1
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Parent = background
		self.instances.label = title

		local drag: TextButton = Instance.new("TextButton")
		drag.BackgroundTransparency = 1
		drag.Text = ""
		drag.Size = UDim2.new(1, 0, 0, 20)
		drag.Modal = true
		drag.Parent = container
		self.instances.drag = drag

		local resize: TextButton = Instance.new("TextButton")
		resize.BackgroundTransparency = 1
		resize.Text = ""
		resize.Position = UDim2.new(1, 0, 1, 0)
		resize.AnchorPoint = Vector2.new(1, 1)
		resize.Size = UDim2.new(0, 13, 0, 13)
		resize.Parent = container
		self.instances.resize = resize

		if UserInputService.TouchEnabled then
			local open: TextButton = Instance.new("TextButton")
			open.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			open.AutoButtonColor = false
			open.Position = UDim2.new(0.5, 0, 0, 0)
			open.Size = UDim2.new(0, 50, 0, 50)
			open.Font = Enum.Font.Arimo
			open.TextSize = 12
			open.TextColor3 = Color3.fromRGB(255, 255, 255)
			open.BackgroundTransparency = 0.5
			open.Text = "Open"
			open.AnchorPoint = Vector2.new(0.5, 0)
			open.Parent = screenGui
			self.instances.open = open

			local uiCorner: UICorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0, 5)
			uiCorner.Parent = open
		end
	end

	function UIBase.into(self: UIBase) : UIBase
		self:_makeInstances()

		local dragInput: InputObject? = nil
		local dragStart: Vector3 = Vector3.zero
		local guiStart: UDim2 = UDim2.new()

		self._trove:Connect(self.instances.drag.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self.dragging = true

				dragStart = input.Position
				guiStart = self.instances.container.Position
				dragInput = input

				local onChanged
				onChanged = self._trove:Connect(input.Changed, function()
					if input.UserInputState == Enum.UserInputState.End then
						self.dragging = false
						self._trove:Remove(onChanged)
						dragInput = nil
					end
				end)
			end
		end)

		self._trove:Connect(UserInputService.InputChanged, function(input: InputObject)
			if self.dragging and input == dragInput then
				local delta: Vector3 = input.Position - dragStart
				self.instances.container.Position = UDim2.new(guiStart.X.Scale, guiStart.X.Offset + delta.X, guiStart.Y.Scale, guiStart.Y.Offset + delta.Y)
			end
		end)

		self._trove:Connect(self.instances.drag.InputChanged, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		self._trove:Add(self.instances.gui)

		local resizeInput: InputObject? = nil
		local resizeStart: Vector3 = Vector3.zero

		self._trove:Connect(self.instances.resize.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self.resizing = true

				dragStart = input.Position
				guiStart = self.instances.container.Position
				resizeInput = input

				local onChanged
				onChanged = self._trove:Connect(input.Changed, function()
					if input.UserInputState == Enum.UserInputState.End then
						self.resizing = false
						self._trove:Remove(onChanged)
						resizeInput = nil
					end
				end)
			end
		end)

		self._trove:Connect(UserInputService.InputChanged, function(input: InputObject)
			if self.resizing and input == resizeInput then
				local uiPosition = self.instances.container.AbsolutePosition
				local mousePosition: Vector2 = Vector2.new(input.Position.X, input.Position.Y)
				local delta: Vector2 = mousePosition - uiPosition

				--> ui size: 500, 450
				local newSize = UDim2.new(0, math.max(500, delta.X), 0, math.max(350, delta.Y))
				self.instances.container.Size = newSize

				local function recursiveResize(parent: UIExtendable)
					type Resizable = {
						children: { [number]: UIIcon | UITab },
						_resize: (self: Resizable) -> (),
					}

					local child = (parent.child :: any) :: Resizable?

					if child then
						if child._resize then
							child:_resize()
						end

						if child.children then
							for _, tab in child.children do
								if tab.child then
									recursiveResize((tab :: any) :: UIExtendable)
								end
							end
						else
							--TODO: Scale sections to fit
							local sections = ((child :: any) :: UISectionHolder).sections

							local left = sections.left[#sections.left]

							if left then
								--left.instances.container.Size
							end
						end
					end
				end

				recursiveResize(self)
			end
		end)

		self._trove:Connect(self.instances.resize.InputChanged, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				resizeInput = input
			end
		end)

		self.menus = {
			dropdown = UIDropdownMenu.new(self),
			colorpicker = UIColorpickerMenu.new(self),
		} :: any

		self._trove:Add(self.menus.dropdown)
		self._trove:Add(self.menus.colorpicker)

		if UserInputService.TouchEnabled then
			self._trove:Connect(self.instances.open.MouseButton1Click, function()
				self:setVisible(not self.visible)
			end)
		end

		return self
	end

	function UIBase.newTabList(self: UIBase) : UITabList
		assert(self.child == nil, "UIBase.newTabList(_) : _ -> expected child to be nil")

		local tabList: UITabList = UITabList.new(self)
		self.child = tabList

		return tabList
	end

	function UIBase.newIconList(self: UIBase) : UIIconList
		assert(self.child == nil, "UIBase.newIconList(_) : _ -> expected child to be nil")

		local iconList: UIIconList = UIIconList.new(self)
		self.child = iconList

		return iconList
	end

	function UIBase.encodeJSON(self: UIBase) : string
		local config = {}

		for flag, feature in self.features do
			if feature.dontSave then
				continue
			end

			if typeof(feature.value) == "table" then
				local clone = table.clone(feature.value)

				for k, v in clone do
					if typeof(v) == "Color3" then
						clone[k] = {v.R, v.G, v.B}
                    elseif typeof(v) == "EnumItem" then
                        clone[k] = {tostring(v.EnumType), v.Name}
					end
				end

				config[flag] = clone
			else
				config[flag] = feature.value
			end
		end

		return HttpService:JSONEncode(config)
	end

	function UIBase.decodeJSON(self, json)
        local jsonDecoded = HttpService:JSONDecode(json)

        local status, err = pcall(function()
            for flag, value in jsonDecoded do
                if not self.features[flag] then continue end
				pcall(function()
					if type(value) == "table" then
						if value.rgb and value.alpha then
							self.features[flag]:set({ rgb = Color3.new(value.rgb[1], value.rgb[2], value.rgb[3]), alpha = value.alpha })
						elseif value.key and value.mode then
							self.features[flag]:set({key = Enum[value.key[1]][value.key[2]], mode = value.mode})
						else
							self.features[flag]:set(value)
						end
					else
						self.features[flag]:set(value)
					end
				end)
            end
        end)

        return status, err
    end

	function UIBase.Finish(self: UIBase)
		setidentity(8)
		self.instances.gui.Parent = CoreGui
	end

	function UIBase.Destroy(self: UIBase)
		self._trove:Clean()
	end
end

type ColorpickerState = {
	rgb: Color3,
	alpha: number,
}

type UIColorpicker = UIFeature<ColorpickerState> & {
	instances: {
		container: Frame,
		button: TextButton,
		gradient: UIGradient,
	},

	open: boolean,
	hasAlpha: boolean,

	--_makeInstances: (self: UIColorpicker, parent: UIToggle | UILabel) -> (),
}

local UIColorpicker = {}
UIColorpicker.__index = UIColorpicker
do
	function UIColorpicker.new(parent: UIToggle | UILabel, flag: string, base: UIBase, hasAlpha: boolean) : UIColorpicker
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UIColorpicker)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = { rgb = Color3.new(), alpha = 0 }
		self.hasAlpha = hasAlpha

		return UIColorpicker.into((self :: any) :: UIColorpicker, parent, base, flag)
	end

	function UIColorpicker.set(self: UIColorpicker, value: ColorpickerState) : UIColorpicker
		if self.value.rgb == value.rgb and self.value.alpha == value.alpha then
			return self
		end

		local color = value.rgb
		local top = Color3.fromRGB(math.min(255, color.R * 255 + 20), math.min(255, color.G * 255 + 20), math.min(255, color.B * 255 + 20))
		local bottom = Color3.fromRGB(math.max(0, color.R * 255 - 20), math.max(0, color.G * 255 - 20), math.max(0, color.B * 255 - 20))

		self.instances.gradient.Color = ColorSequence.new(top, bottom)

		self.value = value
		self.changed:Fire(self.value)

		return self
	end

	function UIColorpicker._makeInstances(self: UIColorpicker, parent: UIToggle | UILabel)
		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		container.BorderSizePixel = 1
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.Size = UDim2.new(0, 40, 1, 0)
		self.instances.container = container

		local inline: Frame = Instance.new("Frame")
		inline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.BorderSizePixel = 0
		inline.Parent = container

		local button: TextButton = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.TextStrokeTransparency = 0
		button.Text = ""
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		button.BackgroundTransparency = 0
		button.Parent = inline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Parent = button
		self.instances.gradient = gradient

		container.Parent = parent.instances.layout
		self.instances.button = button
	end

	function UIColorpicker.into(self: UIColorpicker, parent: UIToggle | UILabel, base: UIBase, flag: string) : UIColorpicker
		self:_makeInstances(parent)
		self:set({ rgb = Color3.fromRGB(255, 255, 225), alpha = 0 })

		self._trove:Connect(self.instances.button.MouseButton1Click, function()
			local inputPos = UserInputService:GetMouseLocation() + Vector2.new(0, GuiService:GetGuiInset().Y)
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self.open = not self.open

			if self.open then
				base.menus.colorpicker:attach(self, base :: any)
			else
				base.menus.colorpicker:detach(base :: any)
			end
		end)

		base.features[flag] = self
		return self
	end
end

type KeybindState = {
	key: (Enum.KeyCode | Enum.UserInputType)?,
	mode: "Always" | "Toggle" | "Hold" | "Release" | "Tap",
}

type UIKeybind = UIFeature<KeybindState> & {
	instances: {
		container: Frame,
		button: TextButton,
	},

	active: boolean,
	activeChanged: Signal<boolean>,
	binding: boolean,
	modes: { string },

	isInputKey: (self: UIKeybind, input: InputObject) -> boolean,

	_setActive: (self: UIKeybind, state: boolean) -> (),
	_makeInstances: (self: UIKeybind, parent: UIToggle | UILabel) -> (),
}

local UIKeybind = {}
UIKeybind.__index = UIKeybind
do
	function UIKeybind.new(parent: UIToggle | UILabel, flag: string, modes: { string }, base: UIBase)
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UIKeybind)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = {}

		self.binding = false
		self.active = false
		self.activeChanged = self._trove:Add(Signal.new())

		self.modes = modes

		return UIKeybind.into((self :: any) :: UIKeybind, parent, base, flag)
	end

	function UIKeybind.set(self: UIKeybind, value: KeybindState) : UIKeybind
		if self.value.key == value.key and self.value.mode == value.mode and not self.binding then
			return self
		end

		if value.key == Enum.UserInputType.MouseMovement then
			return self
		end

		self.instances.button.Text = string.format("%s: %s", value.mode, value.key and value.key.Name or "None")

		self.value = value
		self.changed:Fire(self.value)
		return self
	end

	function UIKeybind._setActive(self: UIKeybind, state: boolean)
		if self.active == state then
			return
		end

		self.active = state
		self.activeChanged:Fire(self.active)
	end

	function UIKeybind.isInputKey(self: UIKeybind, input: InputObject) : boolean
		local key = self.value.key

		if not key then
			return false
		end

		if key.EnumType == Enum.KeyCode and input.KeyCode ~= key :: Enum.KeyCode then
			return false
		end

		if key.EnumType == Enum.UserInputType and input.UserInputType ~= key :: Enum.UserInputType then
			return false
		end

		return true
	end

	function UIKeybind._makeInstances(self: UIKeybind, parent: UIToggle | UILabel)
		local container: Frame = Instance.new("Frame")
		container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		container.BorderSizePixel = 1
		container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		container.Size = UDim2.new(0, 0, 1, 0)
		self.instances.container = container

		local inline: Frame = Instance.new("Frame")
		inline.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.BorderSizePixel = 0
		inline.Parent = container

		local button: TextButton = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextStrokeTransparency = 0
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.Font = Enum.Font.Arial
		button.TextSize = 12
		button.BackgroundTransparency = 1
		button.Parent = inline

		container.Parent = parent.instances.layout
		self.instances.button = button
	end

	function UIKeybind.into(self: UIKeybind, parent: UIToggle | UILabel, base: UIBase, flag: string) : UIKeybind
		self:_makeInstances(parent)

		self._trove:Connect(self.instances.button:GetPropertyChangedSignal("TextBounds"), function()
			self.instances.container.Size = UDim2.new(0, self.instances.button.TextBounds.X + 8, 1, 0)
		end)

		self._trove:Connect(self.changed :: any, function(state: KeybindState)
			self:_setActive(state.mode == "Always")
		end)

		self:set({ key = nil, mode = self.modes[1] :: any })

		local disable_keybind = false

		self._trove:Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessedEvent: boolean)
			if not self:isInputKey(input) or gameProcessedEvent then
				return
			end

			if disable_keybind then
				disable_keybind = false
				return
			end

			local mode = self.value.mode

			if mode == "Toggle" or mode == "Tap" then
				self:_setActive(not self.active)
			elseif mode == "Hold" or mode == "Release" then
				self:_setActive(mode == "Hold")
			end
		end)

		self._trove:Connect(UserInputService.InputEnded, function(input: InputObject, gameProcessedEvent: boolean)
			if not self:isInputKey(input) or gameProcessedEvent then
				return
			end

			local mode = self.value.mode

			if mode == "Hold" or mode == "Release" then
				self:_setActive(mode == "Release")
			end
		end)

		local inputBegan, inputEnded

		self._trove:Connect(self.instances.button.InputEnded, function(input: InputObject)
			if base.activeMenu == "dropdown" and insideFrame(input.Position, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(input.Position, base.menus.colorpicker.instances.container) then
				return
			end

			if base.binding then
				return
			end

			--> WARN: DO NOT allow mobile users
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				base.binding = self
				self.binding = true
				self.instances.button.Text = "..."

				--> HOW is this fired when connecting the signal AFTER click (ROBLOX ISSUE, DO NOT REMOVE)
				local debounce = true

				local connection
				connection = self._trove:Connect(UserInputService.InputBegan, function(input: InputObject)
					if debounce then
						debounce = false
						return
					end

					if input.UserInputType == Enum.UserInputType.MouseMovement then
						return
					end

					local key: (Enum.KeyCode | Enum.UserInputType)?

					if input.KeyCode ~= Enum.KeyCode.Backspace then
						if input.KeyCode ~= Enum.KeyCode.Unknown then
							key = input.KeyCode
						else
							key = input.UserInputType
						end
					end

					disable_keybind = true

					self:set({ key = key, mode = self.value.mode })
					self.binding = false
					base.binding = nil

					self._trove:Remove(connection)
				end)
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				local index = table.find(self.modes, self.value.mode) :: number
				self:set({ key = self.value.key, mode = self.modes[(index % #self.modes) + 1] :: any })
			end
		end)

		base.features[flag] = self
		return self
	end
end

type UIToggle = UIFeature<boolean> & {
	instances: {
		button: TextButton,
		label: TextLabel,
		gradient: UIGradient,
		layout: Frame,
	},

	base: UIBase,

	newColorpicker: (self: UIToggle, flag: string) -> UIColorpicker,
	newKeybind: (self: UILabel, flag: string, modes: { string }?) -> UIKeybind,

	setLabel: (self: UIToggle, label: string) -> UIToggle,
	_makeInstances: (self: UIToggle, parent: UISection) -> (),
}

local UIToggle = {}
UIToggle.__index = UIToggle
do
	function UIToggle.new(parent: UISection, flag: string)
		assert(flag, "UIToggle.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UIToggle.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UIToggle)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = false

		self.base = base

		parent.instances.container.Size += UDim2.new(0 , 0, 0, 19)
		return UIToggle.into((self :: any) :: UIToggle, parent, base, flag)
	end

	function UISection.newToggle(self: UISection, flag: string) : UIToggle
		return UIToggle.new(self, flag)
	end

	function UIToggle.set(self: UIFeature<boolean>, state: boolean) : UIFeature<boolean>
		if typeof(state) ~= "boolean" then
			warn("UIToggle.set(_, state) : _ -> expected boolean, got " .. typeof(state))
			return self
		end

		local self = self :: UIToggle

		if self.value == state then
			return self
		end

		self.value = state

		local gradient: UIGradient = self.instances.gradient

		if self.value then
			gradient.Color = ColorSequence.new(Color3.fromRGB(60, 180, 230), Color3.fromRGB(10, 130, 180))
		else
			gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		end

		self.changed:Fire(self.value)
		return self
	end

	function UIToggle.setLabel(self: UIToggle, label: string) : UIToggle
		assert(label, "UIToggle.setLabel(_, label) : _ -> expected string, got nil")
		assert(typeof(label) == "string", "UIToggle.setLabel(_, label) : _ -> expected string, got " .. typeof(label))

		self.instances.label.Text = label
		return self
	end

	function UIToggle.newKeybind(self: UIToggle, flag: string, modes: { string }?) : UIKeybind
		return (UIKeybind.new(self, flag, modes or { "Always", "Toggle", "Hold", "Release" }, self.base) :: any) :: UIKeybind
	end

	function UIToggle.newColorpicker(self: UILabel, flag: string, hasAlpha: boolean?) : UIColorpicker
		return (UIColorpicker.new(self, flag, self.base, hasAlpha or false) :: any) :: UIColorpicker
	end

	function UIToggle._makeInstances(self: UIToggle, parent: UISection)
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.Size = UDim2.new(1, 0, 0, 15)
		button.Text = ""

		local outline: Frame = Instance.new("Frame")
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.Size = UDim2.new(0, 13, 0, 13)
		outline.Position = UDim2.new(0, 5, 0.5, 0)
		outline.AnchorPoint = Vector2.new(0, 0.5)
		outline.Parent = button

		local inline: Frame = Instance.new("Frame")
		inline.BorderSizePixel = 0
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inline.Parent = outline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		gradient.Rotation = 90
		gradient.Parent = inline
		self.instances.gradient = gradient

		local label: TextLabel = Instance.new("TextLabel")
		label.Font = Enum.Font.Arial
		label.TextSize = 12
		label.TextStrokeTransparency = 0
		label.Position = UDim2.new(0, 23, 0.5, 0)
		label.Size = UDim2.new(1, -27, 0, 11)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Text = ""
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = button
		self.instances.label = label

		local layout: Frame = Instance.new("Frame")
		layout.Size = UDim2.new(1, -10, 0, 13)
		layout.Position = UDim2.new(0, 5, 0, 1)
		layout.BackgroundTransparency = 1
		layout.Parent = button
		self.instances.layout = layout

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 4)
		listLayout.FillDirection = Enum.FillDirection.Horizontal
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = layout

		button.Parent = parent.instances.canvas
		self.instances.button = button
	end

	function UIToggle.into(self: UIToggle, parent: UISection, base: UIBase, flag: string) : UIToggle
		self:_makeInstances(parent)

		self._trove:Connect(self.instances.button.MouseButton1Click, function(input)
			local inputPos = UserInputService:GetMouseLocation() + Vector2.new(0, GuiService:GetGuiInset().Y)
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self:set(not self.value)
		end)

		base.features[flag] = self
		return self
	end
end

type UISlider = UIFeature<number> & {
	instances: {
		outline: TextButton,
		inline: Frame,
		scale: Frame,
		gradient: UIGradient,
		label: TextLabel,
		plus: TextButton,
		minus: TextButton,
		value: TextLabel,
	},

	min: number,
	max: number,
	decimals: number,
	minText: string,

	setLabel: (self: UISlider, label: string) -> UISlider,
	_makeInstances: (self: UISlider, parent: UISection) -> (),
}

local UISlider = {}
UISlider.__index = UISlider
do
	function UISlider.new(parent: UISection, flag: string, min: number?, max: number?, decimals: number?, minText: string?)
		assert(flag, "UISlider.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UISlider.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UISlider)
		self._trove = parent._trove:Extend()

		self.min = min or 0
		self.max = max or 100
		self.decimals = decimals or 1
		self.minText = minText

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = nil

		parent.instances.container.Size += UDim2.new(0, 0, 0, 30)
		return UISlider.into((self :: any) :: UISlider, parent, base, flag)
	end

	function UISection.newSlider(self: UISection, flag: string, min: number?, max: number?, decimals: number?, minText: string?) : UISlider
		return UISlider.new(self, flag, min, max, decimals, minText)
	end

	function UISlider.set(self: UIFeature<number>, value: number) : UIFeature<number>
		if typeof(value) ~= "number" then
			warn("UISlider.set(_, value) : _ -> expected number, got " .. typeof(value))
			return self
		end

		local self = self :: UISlider

		local value = math.clamp(math.round(value * self.decimals) / self.decimals, self.min, self.max)
		local equal = self.value == value

		self.value = value
		self.instances.scale.Size = UDim2.new((self.value - self.min) / (self.max - self.min), 0, 1, 0)
		self.instances.value.Text = (self.value == self.min and self.minText) or string.format("%s/%s", tostring(self.value), tostring(self.max))

		if not equal then
			self.changed:Fire(self.value)
		end

		return self
	end

	function UISlider.setLabel(self: UISlider, label: string) : UISlider
		assert(label, "UISlider.setLabel(_, label) : _ -> expected string, got nil")
		assert(typeof(label) == "string", "UISlider.setLabel(_, label) : _ -> expected string, got " .. typeof(label))

		self.instances.label.Text = label
		return self
	end

	function UISlider._makeInstances(self: UISlider, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(1, 0, 0, 26)

		local label: TextLabel = Instance.new("TextLabel")
		label.Font = Enum.Font.Arial
		label.TextSize = 12
		label.TextStrokeTransparency = 0
		label.Position = UDim2.new(0, 5, 0, 1)
		label.Size = UDim2.new(1, -6, 0, 11)
		label.Text = ""
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container
		self.instances.label = label

		local outline: TextButton = Instance.new("TextButton")
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.Size = UDim2.new(1, -10, 0, 10)
		outline.Position = UDim2.new(0, 5, 0, 15)
		outline.Text = ""
		outline.AutoButtonColor = false
		outline.Parent = container
		self.instances.outline = outline

		local inline: Frame = Instance.new("Frame")
		inline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inline.BorderSizePixel = 0
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Parent = outline
		self.instances.inline = inline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		gradient.Rotation = 90
		gradient.Parent = inline

		local scale: Frame = Instance.new("Frame")
		scale.BorderSizePixel = 0
		scale.Size = UDim2.new(0.5, 0, 1, 0)
		scale.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		scale.BorderSizePixel = 0
		scale.Parent = inline
		self.instances.scale = scale

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(60, 180, 230), Color3.fromRGB(10, 130, 180))
		gradient.Rotation = 90
		gradient.Parent = scale

		local plus: TextButton = Instance.new("TextButton")
		plus.Text = "+"
		plus.BackgroundTransparency = 1
		plus.Size = UDim2.new(0, 11, 0, 11)
		plus.Font = Enum.Font.Arial
		plus.TextSize = 12
		plus.Position = UDim2.new(1, -13, 0, 0)
		plus.TextStrokeTransparency = 0
		plus.TextColor3 = Color3.fromRGB(255, 255, 255)
		plus.Parent = container
		self.instances.plus = plus

		local minus: TextButton = Instance.new("TextButton")
		minus.Text = "-"
		minus.BackgroundTransparency = 1
		minus.Size = UDim2.new(0, 11, 0, 11)
		minus.Font = Enum.Font.Arial
		minus.TextSize = 12
		minus.Position = UDim2.new(1, -26, 0, 0)
		minus.TextStrokeTransparency = 0
		minus.TextColor3 = Color3.fromRGB(255, 255, 255)
		minus.Parent = container
		self.instances.minus = minus

		local value: TextLabel = Instance.new("TextLabel")
		value.Font = Enum.Font.Arial
		value.TextSize = 12
		value.TextStrokeTransparency = 0
		value.Position = UDim2.new(0, 0, 0, 0)
		value.Size = UDim2.new(1, 0, 1, 0)
		value.Text = "undefined"
		value.BackgroundTransparency = 1
		value.TextColor3 = Color3.fromRGB(255, 255, 255)
		value.TextXAlignment = Enum.TextXAlignment.Center
		value.Parent = inline
		self.instances.value = value

		container.Parent = parent.instances.canvas
	end

	function UISlider.into(self: UISlider, parent: UISection, base: UIBase, flag: string) : UISlider
		self:_makeInstances(parent)
		self:set((self.min + self.max) / 2)

		local dragInput: InputObject?
		local dragging: boolean = false

		local onMouseMove = function(input: InputObject)
			if dragging and input == dragInput then
				local inline = self.instances.inline
				local position = input.Position

				local percent = math.clamp((position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X, 0, 1)
				self:set(self.min + (self.max - self.min) * percent)
			end
		end

		local connection = self._trove:Connect(UserInputService.InputChanged, onMouseMove)

		self._trove:Connect(base.visibilityChanged :: any, function(state: boolean)
			if not state then
				dragging = false
				self._trove:Remove(connection)
				return
			end

			connection = self._trove:Connect(UserInputService.InputChanged, onMouseMove)
		end)

		self._trove:Connect(self.instances.outline.InputBegan, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if base.activeMenu == "dropdown" and insideFrame(input.Position, base.menus.dropdown.instances.container) then
					return
				end

				if base.activeMenu == "color" and insideFrame(input.Position, base.menus.colorpicker.instances.container) then
					return
				end

				dragging = true
				dragInput = input

				onMouseMove(input)

				local onChanged
				onChanged = self._trove:Connect(input.Changed, function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						self._trove:Remove(onChanged)
						dragInput = nil
					end
				end)
			end
		end)

		self._trove:Connect(self.instances.outline.InputChanged, function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		self._trove:Connect(self.instances.plus.MouseButton1Click, function(input)
			local inputPos = UserInputService:GetMouseLocation() + Vector2.new(0, GuiService:GetGuiInset().Y)
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self:set(self.value + (1 / self.decimals))
		end)

		self._trove:Connect(self.instances.minus.MouseButton1Click, function(input: InputObject)
			local inputPos = UserInputService:GetMouseLocation() + Vector2.new(0, GuiService:GetGuiInset().Y)
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self:set(self.value - (1 / self.decimals))
		end)

		base.features[flag] = self
		return self
	end
end

type UIDropdown = UIFeature<{ [string]: boolean } | string?> & {
	instances: {
		outline: TextButton,
		value: TextLabel,
		open: TextLabel,
	},

	parent: UISection,
	base: UIBase,
	menu: UIDropdownMenu?,

	onOptionAdded: Signal<{ string } | string?>,
	onOptionRemoved: Signal<{ string } | string?>,

	multi: boolean,
	options: { string },
	add: (self: UIDropdown, element: string) -> (),
	remove: (self: UIDropdown, element: string) -> (),
	setOptions: (self: UIDropdown, newOptions: table) -> (),

	open: boolean,
	setOpen: (self: UIDropdown, state: boolean, base: UIBase) -> (),

	_makeInstances: (self: UIDropdown, parent: UISection) -> (),
}

local UIDropdown = {}
UIDropdown.__index = UIDropdown
do
	function UIDropdown.new(parent: UISection, flag: string, multi: boolean, options: { string }, optionsCallback: any?, closeOnSelect: boolean?, dontSave: boolean?)
		assert(flag, "UIDropdown.new(_, flag, _) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UIDropdown.new(_, flag, _) : _ -> expected string, got " .. typeof(flag))
		assert(options, "todo: error")
		assert(typeof(options) == "table", "todo: error")

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UIDropdown)
		self._trove = parent._trove:Extend()

		self.base = base

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = nil

		self.onOptionAdded = self._trove:Add(Signal.new())
		self.onOptionRemoved = self._trove:Add(Signal.new())

		self.open = false
		self.options = options
		self.optionsCallback = optionsCallback
		self.closeOnSelect = closeOnSelect
		self.dontSave = dontSave

		self.multi = multi

		parent.instances.container.Size += UDim2.new(0, 0, 0, 24)
		return UIDropdown.into((self :: any) :: UIDropdown, parent, base, flag)
	end

	function UISection.newDropdown(self: UISection, flag: string, multi: boolean, options: { string }, optionsCallback: any?, closeOnSelect: boolean?, dontSave: boolean?) : UIDropdown
		return UIDropdown.new(self, flag, multi, options, optionsCallback, closeOnSelect, dontSave)
	end

	function UIDropdown.add(self: UIDropdown, option: string)
		if not table.find(self.options, option) then
			table.insert(self.options, option)
			self.onOptionAdded:Fire(option)
		end
	end

	function UIDropdown.remove(self: UIDropdown, option: string)
		local index = table.find(self.options, option)

		if index then
			table.remove(self.options, index)
			self.onOptionRemoved:Fire(option)

			local value = self.value

			if typeof(value) == "table" then
				if value[option] then
					value[option] = nil

					self:set(value)
				end
			else
				if self.value == option then
					self:set(self.options[1])
				end
			end
		end
	end

	function UIDropdown.setOptions(self: UIDropdown, newOptions: table)
		for _, option in self.options do
			self:remove(option)
		end

		self.options = table.clone(newOptions)
		for _, option in newOptions do
			self.onOptionAdded:Fire(option)
		end
	end

	function UIDropdown._makeInstances(self: UIDropdown, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 20)
		container.BackgroundTransparency = 1

		local outline: TextButton = Instance.new("TextButton")
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.Position = UDim2.new(0, 5, 0, 0)
		outline.Size = UDim2.new(1, -10, 0, 18)
		outline.AutoButtonColor = false
		outline.Text = ""
		outline.Parent = container
		self.instances.outline = outline

		local inline: Frame = Instance.new("Frame")
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inline.BorderSizePixel = 0
		inline.Parent = outline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		gradient.Rotation = 90
		gradient.Parent = inline

		local value: TextLabel = Instance.new("TextLabel")
		value.Font = Enum.Font.Arial
		value.TextSize = 12
		value.TextStrokeTransparency = 0
		value.Position = UDim2.new(0, 4, 0.5, 0)
		value.Size = UDim2.new(1, -18, 0, 11)
		value.AnchorPoint = Vector2.new(0, 0.5)
		value.Text = "None"
		value.BackgroundTransparency = 1
		value.TextColor3 = Color3.fromRGB(255, 255, 255)
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.TextTruncate = Enum.TextTruncate.AtEnd
		value.Parent = inline
		self.instances.value = value

		local open: TextLabel = Instance.new("TextLabel")
		open.Font = Enum.Font.Arial
		open.TextSize = 12
		open.TextStrokeTransparency = 0
		open.Position = UDim2.new(0, 5, 0.5, -1)
		open.Size = UDim2.new(1, -8, 0, 11)
		open.AnchorPoint = Vector2.new(0, 0.5)
		open.Text = "+"
		open.BackgroundTransparency = 1
		open.TextColor3 = Color3.fromRGB(255, 255, 255)
		open.TextXAlignment = Enum.TextXAlignment.Right
		open.Parent = inline
		self.instances.open = open

		container.Parent = parent.instances.canvas
	end

	function UIDropdown.setOpen(self: UIDropdown, state: boolean, base: UIBase)
		if self.open == state then
			return
		end

		if self.optionsCallback then
			local prev = self.value
			self:setOptions(self.optionsCallback())
			self:set(prev)
		end

		self.open = state
		self.instances.open.Text = self.open and "-" or "+"
	end

	function UIDropdown.set(self: UIDropdown, value: { [string]: boolean } | string?)
		if self.value == value and not self.multi then
			return
		end

		self.value = value

		if typeof(value) == "table" then
			local res = ""

			for _, option in self.options do
				if value[option] then
					res ..= option .. ", "
				end
			end

			if string.len(res) == 0 then
				self.instances.value.Text = "..."
			else
				self.instances.value.Text = string.sub(res, 1, string.len(res) - 2)
			end
		else
			self.instances.value.Text = value or "None"
		end

		self.changed:Fire(self.value)
	end

	function UIDropdown.into(self: UIDropdown, parent: UISection, base: UIBase, flag: string) : UIDropdown
		self:_makeInstances(parent)

		if not self.multi then
			self:set(self.options[1])
		else
			self:set({})
		end

		self._trove:Connect(self.instances.outline.MouseButton1Click, function()
			local inputPos = UserInputService:GetMouseLocation()
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self:setOpen(not self.open, base)

			if self.open then
				base.menus.dropdown:attach(self, base :: any)
			else
				base.menus.dropdown:detach(base :: any)
			end
		end)

		base.features[flag] = self
		return self
	end
end

type UIButton = UIFeature<nil> & {
	instances: {
		button: TextButton,
	},

	setLabel: (self: UIButton, label: string) -> UIToggle,
	_makeInstances: (self: UIButton, parent: UISection) -> (),
}

local UIButton = {}
UIButton.__index = UIButton
do
	function UIButton.new(parent: UISection, flag: string)
		assert(flag, "UIButton.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UIButton.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UIButton)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())

		parent.instances.container.Size += UDim2.new(0 , 0, 0, 24)
		return UIButton.into((self :: any) :: UIButton, parent, base, flag)
	end

	function UISection.newButton(self: UISection, flag: string) : UIButton
		return UIButton.new(self, flag)
	end

	function UIButton.set(self: UIFeature<nil>, state: nil) : UIFeature<nil>
		return self
	end

	function UIButton.setLabel(self: UIButton, label: string) : UIButton
		assert(label, "UIButton.setLabel(_, label) : _ -> expected string, got nil")
		assert(typeof(label) == "string", "UIButton.setLabel(_, label) : _ -> expected string, got " .. typeof(label))

		self.instances.button.Text = label
		return self
	end

	function UIButton._makeInstances(self: UIButton, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 20)
		container.BackgroundTransparency = 1

		local outline: Frame = Instance.new("Frame")
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.Position = UDim2.new(0, 5, 0, 0)
		outline.Size = UDim2.new(1, -10, 0, 18)
		outline.Parent = container

		local inline: Frame = Instance.new("Frame")
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inline.BorderSizePixel = 0
		inline.Parent = outline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		gradient.Rotation = 90
		gradient.Parent = inline

		local button: TextButton = Instance.new("TextButton")
		button.Font = Enum.Font.Arial
		button.TextSize = 12
		button.TextStrokeTransparency = 0
		button.Position = UDim2.new(0, 0, 0, 0)
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.Parent = inline
		self.instances.button = button

		container.Parent = parent.instances.canvas
	end

	function UIButton.into(self: UIButton, parent: UISection, base: UIBase, flag: string) : UIButton
		self:_makeInstances(parent)

		self._trove:Connect(self.instances.button.MouseButton1Down, function()
			local inputPos = UserInputService:GetMouseLocation() + Vector2.new(0, GuiService:GetGuiInset().Y)
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self.instances.button.TextColor3 = Color3.fromRGB(55, 175, 225)
		end)

		self._trove:Connect(self.instances.button.MouseButton1Click, function()
			local inputPos = UserInputService:GetMouseLocation() + Vector2.new(0, GuiService:GetGuiInset().Y)
			if base.activeMenu == "dropdown" and insideFrame(inputPos, base.menus.dropdown.instances.container) then
				return
			end

			if base.activeMenu == "color" and insideFrame(inputPos, base.menus.colorpicker.instances.container) then
				return
			end

			self.changed:Fire()
		end)

		self._trove:Connect(self.instances.button.InputEnded, function()
			self.instances.button.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)

		base.features[flag] = self
		return self
	end
end

type UIList = UIFeature<string?> & {
	instances: {
		layout: ScrollingFrame,
	},

	size: number,
	options: { [string]: Trove },

	add: (self: UIList, option: string) -> (),
	remove: (self: UIList, option: string) -> (),

	_reset: (self: UIList) -> (),
	_makeInstances: (self: UIList, parent: UISection) -> (),
}

local UIList = {}
UIList.__index = UIList
do
	function UIList.new(parent: UISection, flag: string, size: number, options: { string })
		assert(flag, "UIList.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UIList.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UIList)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())

		self.options = options
		self.size = size * 18 + 4

		parent.instances.container.Size += UDim2.new(0, 0, 0, self.size + 4)
		return UIList.into((self :: any) :: UIList, parent, base, flag)
	end

	function UISection.newList(self: UISection, flag: string, size: number, options: { string }) : UIList
		return UIList.new(self, flag, size, options)
	end

	function UIList.set(self: UIFeature<string?>, value: string?) : UIFeature<string?>
		if self.value == value then
			return self
		end

		self.value = value
		self.changed:Fire(self.value)
		return self
	end

	function UIList.add(self: UIList, option: string)
		if self.options[option] then
			return
		end

		local trove = self._trove:Extend()

		local container: Frame = Instance.new("Frame")
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(1, 0, 0, 18)

		local button: TextButton = Instance.new("TextButton")
		button.Text = option
		button.Size = UDim2.new(1, 0, 1, 0)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextStrokeTransparency = 0
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.Font = Enum.Font.Arial
		button.TextSize = 12
		button.BackgroundTransparency = 1
		button.Parent = container

		container.Parent = self.instances.layout

		trove:Connect(button.MouseButton1Click, function()
			self:set(option)
		end)

		local function updateColors()
			if option == self.value then
				button.TextColor3 = Color3.fromRGB(55, 175, 225)
			else
				button.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end

		updateColors()
		trove:Connect(self.changed :: any, updateColors)

		trove:Add(container)
		self.options[option] = trove
	end

	function UIList.remove(self: UIList, option: string)
		self._trove:Remove(self.options[option])
		self.options[option] = nil
		self:set(nil)
	end

	function UIList._reset(self: UIList)
		for option in self.options do
			self:set(option)
			break
		end
	end

	function UIList._makeInstances(self: UIList, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, self.size)
		container.BackgroundTransparency = 1

		local outline: Frame = Instance.new("Frame")
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.Position = UDim2.new(0, 5, 0, 0)
		outline.Size = UDim2.new(1, -10, 1, 0)
		outline.Parent = container

		local layout: ScrollingFrame = Instance.new("ScrollingFrame")
		layout.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		layout.BorderSizePixel = 0
		layout.Position = UDim2.new(0, 1, 0, 1)
		layout.Size = UDim2.new(1, -2, 1, -2)
		layout.AutomaticCanvasSize = Enum.AutomaticSize.Y
		layout.CanvasSize = UDim2.new(0, 0, 0, 0)
		layout.ScrollBarImageColor3 = Color3.fromRGB(55, 175, 225)
		layout.ScrollingDirection = Enum.ScrollingDirection.Y
		layout.ScrollBarThickness = 4
		layout.TopImage = "rbxasset://textures/AvatarEditorImages/LightPixel.png"
		layout.MidImage = "rbxasset://textures/AvatarEditorImages/LightPixel.png"
		layout.BottomImage = "rbxasset://textures/AvatarEditorImages/LightPixel.png"
		layout.Parent = outline
		self.instances.layout = layout

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = layout

		container.Parent = parent.instances.canvas
	end

	function UIList.into(self: UIList, parent: UISection, base: UIBase, flag: string) : UIList
		self:_makeInstances(parent)
		self:_reset()

		base.features[flag] = self
		return self
	end
end

type UITextBox = UIFeature<string> & {
	instances: {
		textbox: TextBox,
	},

	setLabel: (self: UITextBox, label: string) -> UITextBox,
	_makeInstances: (self: UITextBox, parent: UISection) -> (),
}

local UITextBox = {}
UITextBox.__index = UITextBox
do
	function UITextBox.new(parent: UISection, flag: string)
		assert(flag, "UITextBox.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UITextBox.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UITextBox)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
        self.focuslost = self._trove:Add(Signal.new())

		parent.instances.container.Size += UDim2.new(0 , 0, 0, 24)
		return UITextBox.into((self :: any) :: UITextBox, parent, base, flag)
	end

	function UISection.newTextBox(self: UISection, flag: string) : UITextBox
		return UITextBox.new(self, flag)
	end

	function UITextBox.set(self: UIFeature<string>, text: string) : UIFeature<string>
		local textbox = (self :: UITextBox).instances.textbox
		local text = string.sub(text, 1, 20)

		if self.value == text then
			textbox.Text = text
			return self
		end

		textbox.Text = text

		self.value = text
		self.changed:Fire(self.value)
		return self
	end

	function UITextBox.setLabel(self: UITextBox, label: string) : UITextBox
		assert(label, "UITextBox.setLabel(_, label) : _ -> expected string, got nil")
		assert(typeof(label) == "string", "UITextBox.setLabel(_, label) : _ -> expected string, got " .. typeof(label))

		self.instances.textbox.PlaceholderText = label
		return self
	end

	function UITextBox._makeInstances(self: UITextBox, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 20)
		container.BackgroundTransparency = 1

		local outline: Frame = Instance.new("Frame")
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.Position = UDim2.new(0, 5, 0, 0)
		outline.Size = UDim2.new(1, -10, 0, 18)
		outline.Parent = container

		local inline: Frame = Instance.new("Frame")
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inline.BorderSizePixel = 0
		inline.Parent = outline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		gradient.Rotation = 90
		gradient.Parent = inline

		local textbox: TextBox = Instance.new("TextBox")
		textbox.Font = Enum.Font.Arial
		textbox.TextSize = 12
		textbox.TextStrokeTransparency = 0
		textbox.Position = UDim2.new(0, 0, 0, 0)
		textbox.Size = UDim2.new(1, 0, 1, 0)
		textbox.BackgroundTransparency = 1
		textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
		textbox.TextXAlignment = Enum.TextXAlignment.Center
		textbox.Text = ""
		textbox.ClearTextOnFocus = false
		textbox.Parent = inline
		self.instances.textbox = textbox

		container.Parent = parent.instances.canvas
	end

	function UITextBox.into(self: UITextBox, parent: UISection, base: UIBase, flag: string) : UITextBox
		self:_makeInstances(parent)
		self:set("")

		local textbox = self.instances.textbox

		self._trove:Connect(textbox:GetPropertyChangedSignal("Text"), function()
			textbox.TextXAlignment = Enum.TextXAlignment.Center
			self:set(textbox.Text)
		end)

        self._trove:Connect(textbox.FocusLost, function(...)
			self.focuslost:Fire(self.value, ...)
		end)

		base.features[flag] = self
		return self
	end
end

type UILabel = UIFeature<nil> & {
	instances: {
		label: TextLabel,
		layout: Frame,
	},

	base: UIBase,

	newColorpicker: (self: UILabel, flag: string) -> UIColorpicker,
	newKeybind: (self: UILabel, flag: string, modes: { string }?) -> UIKeybind,

	setLabel: (self: UILabel, label: string) -> UILabel,
    setColor: (self: UILabel, color: Color3) -> UILabel,
	_makeInstances: (self: UILabel, parent: UISection) -> (),
}

local UILabel = {}
UILabel.__index = UILabel
do
	function UILabel.new(parent: UISection, flag: string)
		assert(flag, "UILabel.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UILabel.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UILabel)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = false

		self.base = base

		parent.instances.container.Size += UDim2.new(0 , 0, 0, 19)
		return UILabel.into((self :: any) :: UILabel, parent, base, flag)
	end

	function UISection.newLabel(self: UISection, flag: string) : UILabel
		return UILabel.new(self, flag)
	end

	function UILabel.set(self: UIFeature<boolean>, state: boolean) : UIFeature<boolean>
		return self
	end

	function UILabel.setLabel(self: UILabel, label: string) : UILabel
		assert(label, "UILabel.setLabel(_, label) : _ -> expected string, got nil")
		assert(typeof(label) == "string", "UILabel.setLabel(_, label) : _ -> expected string, got " .. typeof(label))

		self.instances.label.Text = label
		return self
	end

    function UILabel.setColor(self: UILabel, color: Color3)
        self.instances.label.TextColor3 = color
        return self
    end

	function UILabel.newKeybind(self: UILabel, flag: string, modes: { string }?) : UIKeybind
		return (UIKeybind.new(self, flag, modes or { "Always", "Toggle", "Hold", "Release" }, self.base) :: any) :: UIKeybind
	end

	function UILabel.newColorpicker(self: UILabel, flag: string, hasAlpha: boolean?) : UIColorpicker
		return (UIColorpicker.new(self, flag, self.base, hasAlpha or false) :: any) :: UIColorpicker
	end

	function UILabel._makeInstances(self: UILabel, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 15)
		container.BackgroundTransparency = 1

		local label: TextLabel = Instance.new("TextLabel")
		label.Font = Enum.Font.Arial
		label.TextSize = 12
		label.TextStrokeTransparency = 0
		label.Position = UDim2.new(0, 5, 0.5, 0)
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Size = UDim2.new(1, -10, 0, 11)
		label.Text = ""
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = container
		self.instances.label = label

		local layout: Frame = Instance.new("Frame")
		layout.Size = UDim2.new(1, -10, 0, 13)
		layout.Position = UDim2.new(0, 5, 0, 1)
		layout.BackgroundTransparency = 1
		layout.Parent = container
		self.instances.layout = layout

		local listLayout: UIListLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 4)
		listLayout.FillDirection = Enum.FillDirection.Horizontal
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = layout

		container.Parent = parent.instances.canvas
	end

	function UILabel.into(self: UILabel, parent: UISection, base: UIBase, flag: string) : UILabel
		self:_makeInstances(parent)

		base.features[flag] = self
		return self
	end
end

type UICurveGraph = UIFeature<{ a: Vector2, b: Vector2 }> & {
	instances: {
		container: Frame,
		outline: Frame,
		inline: Frame,

		graph: Frame,
		points: { [number]: Frame },
		controlA: TextButton,
		controlB: TextButton,
	},

	base: UIBase,
	dragging: boolean,

	updatePoints: (self: UICurveGraph) -> (),
	_makeInstances: (self: UICurveGraph, parent: UISection) -> (),
}

local UICurveGraph = {}
UICurveGraph.__index = UICurveGraph
do
	function UICurveGraph.new(parent: UISection, flag: string)
		assert(flag, "UICurveGraph.new(_, flag) : _ -> expected string, got nil")
		assert(typeof(flag) == "string", "UICurveGraph.new(_, flag) : _ -> expected string, got " .. typeof(flag))

		local base: any = parent

		while base.parent do
			base = base.parent
		end

		local base = base :: UIBase
		assert(base.features[flag] == nil, string.format("UIBase.features[\"%s\"] already exists.", flag))

		local self = setmetatable({}, UICurveGraph)
		self._trove = parent._trove:Extend()

		self.instances = {}
		self.instances.points = {}
		self.changed = self._trove:Add(Signal.new())
		self.value = { a = Vector2.new(0, 1), b = Vector2.new(1, 0) }
		self.base = base

		self.dragging = false

		parent.instances.container.Size += UDim2.new(0 , 0, 0, 104)
		return UICurveGraph.into((self :: any) :: UICurveGraph, parent, base, flag)
	end

	function UISection.newCurveGraph(self: UISection, flag: string) : UICurveGraph
		return UICurveGraph.new(self, flag)
	end

	function UICurveGraph.set(self: UIFeature<{ a: Vector2, b: Vector2 }>, value: { a: Vector2, b: Vector2 }) : UIFeature<{ a: Vector2, b: Vector2 }>
		if self.value.a == value.a and self.value.b == value.b then
			return self
		end

		local self = self :: UICurveGraph
		self.value = value
		self:updatePoints()

		self.changed:Fire(self.value)
		return self
	end

	function UICurveGraph.updatePoints(self: UICurveGraph)
		local instances = self.instances
		local size = instances.outline.AbsoluteSize

		local start = size.Y
		local pointA = size.Y * self.value.a.Y * 3
		local pointB = size.Y * self.value.b.Y * 3

		for i = 1, 19 do
			local t = i / 20
			local t_1 = 1 - t
			local p1 = start * t_1 * t_1 * t_1
			local p2 = pointA * t_1 * t_1 * t
			local p3 = pointB * t_1 * t * t

			local point = p1 + p2 + p3

			self.instances.points[i].Position = UDim2.new(i / 20, 0, point / size.Y, 0)
		end

		local value = self.value
		instances.controlA.Position = UDim2.new(value.a.X, 0, value.a.Y, 0)
		instances.controlB.Position = UDim2.new(value.b.X, 0, value.b.Y, 0)
	end

	function UICurveGraph._makeInstances(self: UICurveGraph, parent: UISection)
		local container: Frame = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 100)
		container.BackgroundTransparency = 1

		local outline: Frame = Instance.new("Frame")
		outline.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		outline.BorderSizePixel = 1
		outline.BorderColor3 = Color3.fromRGB(0, 0, 0)
		outline.Size = UDim2.new(1, -10, 1, -2)
		outline.Position = UDim2.new(0, 5, 0, 1)
		outline.Parent = container
		self.instances.outline = outline

		local inline: Frame = Instance.new("Frame")
		inline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		inline.BorderSizePixel = 0
		inline.Size = UDim2.new(1, -2, 1, -2)
		inline.Position = UDim2.new(0, 1, 0, 1)
		inline.Parent = outline
		self.instances.inline = inline

		local gradient: UIGradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(25, 25, 25))
		gradient.Rotation = 90
		gradient.Parent = inline

		for scale = 0.25, 0.75, 0.25 do
			local line = Instance.new("Frame")
			line.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			line.Position = UDim2.new(scale, 0, 0, 0)
			line.BorderSizePixel = 0
			line.Size = UDim2.new(0, 1, 1, 0)
			line.Parent = inline
		end

		for scale = 0.25, 0.75, 0.25 do
			local line = Instance.new("Frame")
			line.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			line.Position = UDim2.new(0, 0, scale, 0)
			line.BorderSizePixel = 0
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Parent = inline
		end

		local graph: Frame = Instance.new("Frame")
		graph.BorderSizePixel = 0
		graph.Size = UDim2.new(1, -6, 1, -6)
		graph.Position = UDim2.new(0, 3, 0, 3)
		graph.BackgroundTransparency = 1
		graph.Parent = inline
		self.instances.graph = graph

		for i = 1, 19 do
			local point = Instance.new("Frame")
			point.BackgroundColor3 = Color3.fromRGB(55, 175, 225)
			point.Position = UDim2.new(i / 20, 0, 0.5, 0)
			point.AnchorPoint = Vector2.new(0.5, 0.5)
			point.BorderSizePixel = 1
			point.BorderColor3 = Color3.fromRGB(0, 0, 0)
			point.Size = UDim2.new(0, 4, 0, 4)
			point.Parent = graph
			self.instances.points[i] = point
		end

		local controlA = Instance.new("TextButton")
		controlA.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		controlA.AnchorPoint = Vector2.new(0.5, 0.5)
		controlA.BorderSizePixel = 1
		controlA.BorderColor3 = Color3.fromRGB(0, 0, 0)
		controlA.Size = UDim2.new(0, 4, 0, 4)
		controlA.Text = ""
		controlA.AutoButtonColor = false
		controlA.Parent = graph
		self.instances.controlA = controlA

		local controlB = Instance.new("TextButton")
		controlB.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		controlB.AnchorPoint = Vector2.new(0.5, 0.5)
		controlB.BorderSizePixel = 1
		controlB.BorderColor3 = Color3.fromRGB(0, 0, 0)
		controlB.Size = UDim2.new(0, 4, 0, 4)
		controlB.Text = ""
		controlB.AutoButtonColor = false
		controlB.Parent = graph
		self.instances.controlB = controlB

		container.Parent = parent.instances.canvas
	end

	function UICurveGraph.into(self: UICurveGraph, parent: UISection, base: UIBase, flag: string) : UICurveGraph
		self:_makeInstances(parent)
		self:updatePoints()

		local base = base :: any

		base:makeDraggable(self.instances.controlA, self._trove, function(input: InputObject)
			local inline = self.instances.graph
			local position = input.Position

			local percentX = math.clamp((position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X, 0, 1)
			local percentY = math.clamp((position.Y - inline.AbsolutePosition.Y) / inline.AbsoluteSize.Y, 0, 1)

			self:set({ a = Vector2.new(percentX, percentY), b = self.value.b })
		end)

		base:makeDraggable(self.instances.controlB, self._trove, function(input: InputObject)
			local inline = self.instances.graph
			local position = input.Position

			local percentX = math.clamp((position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X, 0, 1)
			local percentY = math.clamp((position.Y - inline.AbsolutePosition.Y) / inline.AbsoluteSize.Y, 0, 1)

			self:set({ a = self.value.a, b = Vector2.new(percentX, percentY) })
		end)

		base.features[flag] = self
		return self
	end
end

-- // Global
local hooksinglemetamethod = newcclosure(function(instance, mtName, fn, yappin)
    local cGameMt = table.clone(getrawmetatable(instance))
    setreadonly(cGameMt, false)
    local old = cGameMt[mtName]
    cGameMt[mtName] = fn
    if yappin then
        instance.Changed:Connect(function()
            setrawmetatable(instance, cGameMt)
        end)
    end
    setrawmetatable(instance, cGameMt)
    setreadonly(cGameMt, true)
    return old
end)

local Desync = {new = newcclosure(function(obj, prop, value)
    if type(value) ~= "function" then
        local real = value
        value = function() return real end
    end
    local name = HttpService:GenerateGUID()
    local old = obj[prop]
    local heartbeat = RunService.Heartbeat:Connect(function()
        old = obj[prop]
        obj[prop] = value(old, obj)
    end)
    RunService:BindToRenderStep(name, 1, function()
        obj[prop] = old
    end)
    local desync = {}
    function desync:Set(v)
        value = (type(v) ~= "function" and function() return v end) or v
    end
    function desync:Get()
        return old
    end
    function desync:Disconnect()
        RunService:UnbindFromRenderStep(name)
        heartbeat:Disconnect()
    end
    return desync
end)}

local isnetworkowner = isnetworkowner or newcclosure(function(inst)
    assert(typeof(inst) == "Instance", ("invalid argument #1 to 'isnetworkowner' (Instance expected, got %s)"):format(typeof(inst)))
    return inst.ReceiveAge == 0
end)

local function listen_path(path, added, removed)
    for i,v in path:GetChildren() do
        task.defer(added, v)
    end
    path.ChildAdded:Connect(function(...)
        task.defer(added, ...)
    end)
    if removed then
        path.ChildRemoved:Connect(function(...)
            task.defer(removed, ...)
        end)
    end
end

local function table_search(target, index)
    for i=1,#target do
        if target[i] ~= index then continue end
        return i
    end
end

local function singleThreadOnMultipleToggles(feature, callback)

end

local oldReq = require 
local require = function(module)
    local a,b = pcall(require, module)
    if a then 
        return require(module)
    else 
        return nil
    end 
end

local character = LocalPlayer.Character
local rootPart = character and character:WaitForChild("HumanoidRootPart", 5)
local humanoid = character and character:WaitForChild("Humanoid", 5)

local characterAdded = Signal.new()
local characterRemoving = Signal.new()

if character then characterAdded:Fire(character) end

LocalPlayer.CharacterAdded:Connect(function(char)
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    character = char
    characterAdded:Fire(character)
end)
LocalPlayer.CharacterRemoving:Connect(function()
    character, rootPart = nil, nil
    characterRemoving:Fire()
end)

-- // Fisch
local playerStats = ReplicatedStorage.playerstats:WaitForChild(LocalPlayer.Name)
local coins = playerStats:WaitForChild("Stats"):WaitForChild("coins")
local playerStatSettings = playerStats:WaitForChild("Settings")

local worldData = ReplicatedStorage.world
local animations = ReplicatedStorage.resources:WaitForChild("animations")
local boats = ReplicatedStorage.modules:WaitForChild("vessels")
local sfx = ReplicatedStorage.resources.sounds.sfx

local fishingZones = workspace:WaitForChild("zones"):WaitForChild("fishing")

local baitLibrary = require(ReplicatedStorage.modules.library.bait) or LPH_NO_VIRTUALIZE(function()
	return {
		Bagel = {
			LureSpeed = 0,
			Luck = 25,
			GenerelLuck = 0,
			Resilience = 15,
			Rarity = "Common"
		},
		Garbage = {
			LureSpeed = -250,
			Luck = 0,
			GenerelLuck = 0,
			Resilience = 50,
			Rarity = "Common"
		},
		Worm = {
			LureSpeed = 15,
			Luck = 25,
			GenerelLuck = 0,
			Resilience = 0,
			Rarity = "Common"
		},
		Insect = {
			LureSpeed = 5,
			Luck = 35,
			GenerelLuck = 0,
			Resilience = 0,
			Rarity = "Common"
		},
		Maggot = {
			LureSpeed = -10,
			Luck = 0,
			GenerelLuck = 35,
			Resilience = 0,
			Rarity = "Uncommon"
		},
		Squid = {
			LureSpeed = -25,
			Luck = 55,
			GenerelLuck = 45,
			Resilience = 0,
			Rarity = "Unusual"
		},
		Seaweed = {
			LureSpeed = 20,
			Luck = 35,
			GenerelLuck = 0,
			Resilience = 10,
			Rarity = "Unusual"
		},
		Coral = {
			LureSpeed = 20,
			Luck = 0,
			GenerelLuck = 0,
			Resilience = 20,
			Rarity = "Unusual"
		},
		["Deep Coral"] = {
			LureSpeed = 0,
			Luck = -10,
			GenerelLuck = 0,
			Resilience = 50,
			Rarity = "Legendary"
		},
		Flakes = {
			LureSpeed = 10,
			Luck = 55,
			GenerelLuck = 0,
			Resilience = -3,
			Rarity = "Common"
		},
		Shrimp = {
			LureSpeed = 0,
			Luck = 45,
			GenerelLuck = 25,
			Resilience = -5,
			Rarity = "Uncommon"
		},
		Magnet = {
			LureSpeed = 0,
			Luck = 200,
			GenerelLuck = 0,
			Resilience = 0,
			Rarity = "Unusual"
		},
		["Truffle Worm"] = {
			LureSpeed = -10,
			Luck = 300,
			GenerelLuck = 0,
			Resilience = 0,
			Rarity = "Legendary"
		},
		Minnow = {
			LureSpeed = 0,
			Luck = 65,
			GenerelLuck = 0,
			Resilience = -10,
			Rarity = "Unusual"
		},
		Coal = {
			LureSpeed = 0,
			Luck = 45,
			GenerelLuck = 0,
			Resilience = -10,
			Rarity = "Rare"
		},
		["Rapid Catcher"] = {
			LureSpeed = 35,
			Luck = 0,
			GenerelLuck = 0,
			Resilience = -15,
			Rarity = "Rare"
		},
		["Instant Catcher"] = {
			LureSpeed = 65,
			Luck = 0,
			GenerelLuck = -20,
			Resilience = -15,
			Rarity = "Legendary"
		},
		["Super Flakes"] = {
			LureSpeed = 0,
			Luck = 0,
			GenerelLuck = 70,
			Resilience = -15,
			Rarity = "Rare"
		},
		["Night Shrimp"] = {
			LureSpeed = 15,
			Luck = 0,
			GenerelLuck = 90,
			Resilience = 0,
			Rarity = "Legendary"
		},
		["Fish Head"] = {
			LureSpeed = 10,
			Luck = 150,
			GenerelLuck = 0,
			Resilience = -10,
			Rarity = "Legendary"
		},
		["Weird Algae"] = {
			LureSpeed = -35,
			Luck = 0,
			GenerelLuck = 200,
			Resilience = 0,
			Rarity = "Legendary"
		},
		["Shark Head"] = {
			LureSpeed = -5,
			Luck = 225,
			GenerelLuck = 30,
			Resilience = 10,
			Rarity = "Mythical"
		},
		Give = function(_, v1, v2, v3) --[[ Line: 168 ]] --[[ Name: Give ]]
			if game:GetService("RunService"):IsServer() then
				if v3 == 0 or v3 == nil then
					v3 = 1
				end
				local v4 = require(ReplicatedStorage:WaitForChild("modules"):WaitForChild("character")).PS(v1)
				if v4 and v4:WaitForChild("Stats"):WaitForChild("bait"):FindFirstChild("bait_" .. v2) then
					local l_FirstChild_0 = v4:WaitForChild("Stats"):WaitForChild("bait"):FindFirstChild("bait_" .. v2)
					l_FirstChild_0.Value = l_FirstChild_0.Value + v3
					ReplicatedStorage:WaitForChild("events"):WaitForChild("anno_bait"):FireClient(v1, v2, v3)
				end
			end
		end
	}
end)()

local itemsLibrary = require(ReplicatedStorage.modules.library.items) or LPH_NO_VIRTUALIZE(function()
	local v2 = {
		Items = {
			["Crab Cage"] = {
				Rarity = "Unusual",
				Price = 45
			},
			Firework = {
				Rarity = "Limited",
				Price = 130
			},
			["Conception Conch"] = {
				Rarity = "Mythical",
				Price = 444
			},
			Glider = {
				Rarity = "Rare",
				Price = 900,
				OnlyBuyOne = true
			},
			["Fish Radar"] = {
				Rarity = "Legendary",
				Icon = "rbxassetid://132119413174655",
				Price = 8000,
				OnlyBuyOne = true
			},
			GPS = {
				Rarity = "Uncommon",
				Icon = "rbxassetid://92660360174055",
				Price = 100,
				OnlyBuyOne = true
			},
			["Tempest Totem"] = {
				Rarity = "Rare",
				Price = 2000
			},
			["Windset Totem"] = {
				Rarity = "Rare",
				Price = 2000
			},
			["Sundial Totem"] = {
				Rarity = "Rare",
				Price = 2000
			},
			["Smokescreen Totem"] = {
				Rarity = "Rare",
				Price = 2000
			},
			["Aurora Totem"] = {
				Rarity = "Mythical",
				Price = 500000
			},
			["Meteor Totem"] = {
				Rarity = "Legendary",
				Price = 75000
			},
			["Eclipse Totem"] = {
				Rarity = "Mythical",
				Price = 250000
			},
			["Witches Ingredient"] = {
				Rarity = "Rare",
				Price = 10000
			},
			["Basic Diving Gear"] = {
				Rarity = "Uncommon",
				Price = 3000,
				OnlyBuyOne = true
			},
			["Advanced Diving Gear"] = {
				Rarity = "Unusual",
				Price = 15000,
				OnlyBuyOne = true
			},
			Flippers = {
				Rarity = "Unusual",
				Price = 9000,
				OnlyBuyOne = true
			},
			["Super Flippers"] = {
				Rarity = "Legendary",
				Price = 30000,
				OnlyBuyOne = true
			},
			Tidebreaker = {
				Rarity = "Mythical",
				Price = 80000,
				OnlyBuyOne = true
			},
			["Ancient Thread"] = {
				Rarity = "Exotic",
				SellValue = 700,
				Price = 1e999
			},
			["Magic Thread"] = {
				Rarity = "Exotic",
				SellValue = 250,
				Price = 1e999
			},
			["Lunar Thread"] = {
				Rarity = "Exotic",
				SellValue = 1250,
				Price = 1e999
			},
			Nuke = {
				Rarity = "Exotic",
				Price = 1e999
			},
			Fillionaire = {
				Rarity = "Exotic",
				Price = 1e999
			},
			["Treasure Map"] = {
				Rarity = "Exotic",
				Price = 1e999
			},
			["Handwritten Note"] = {
				Rarity = "Exotic",
				Price = 1e999
			}
		},
		Rarities = {
			[1] = "Trash",
			[2] = "Common",
			[3] = "Uncommon",
			[4] = "Unusual",
			[5] = "Rare",
			[6] = "Legendary",
			[7] = "Mythical",
			[8] = "Exotic",
			[9] = "Limited",
			[10] = "Developer"
		},
		RarityColours = {
			Trash = Color3.fromRGB(145, 145, 145),
			Common = Color3.fromRGB(142, 187, 191),
			Uncommon = Color3.fromRGB(161, 255, 169),
			Unusual = Color3.fromRGB(192, 135, 198),
			Rare = Color3.fromRGB(119, 108, 181),
			Legendary = Color3.fromRGB(240, 181, 109),
			Mythical = Color3.fromRGB(255, 62, 120),
			Exotic = Color3.fromRGB(255, 255, 255),
			Limited = Color3.fromRGB(255, 130, 57),
			Extinct = Color3.fromRGB(54, 73, 159),
			Relic = Color3.fromRGB(120, 255, 183)
		},
		ToInteger = function(_, v1) --[[ Line: 179 ]] --[[ Name: ToInteger ]]
			return math.floor(v1.r * 255) * 65536 + math.floor(v1.g * 255) * 256 + math.floor(v1.b * 255)
		end
	}
	v2.ToHex = function(_, v4) --[[ Line: 183 ]] --[[ Name: ToHex ]]
		local v5 = v2:ToInteger(v4)
		local v6 = ""
		local v7 = {
			"A",
			"B",
			"C",
			"D",
			"E",
			"F"
		}
		repeat
			local v8 = v5 % 16
			local v9 = tostring(v8)
			if v8 >= 10 then
				v9 = v7[1 + v8 - 10]
			end
			v5 = math.floor(v5 / 16)
			v6 = v6 .. v9
		until v5 <= 0
		return "#" .. string.reverse(v6)
	end
	return v2
end)()

local fishLibrary = require(ReplicatedStorage.modules.library.fish) or LPH_NO_VIRTUALIZE(function()
	local l_fish_0 = ReplicatedStorage:WaitForChild("resources"):WaitForChild("animations"):WaitForChild("fish")
local v1 = {
    ["Desolate Deep"] = {
        Trash = 22, 
        Common = 22, 
        Uncommon = 18, 
        Unusual = 17, 
        Rare = 14
    }, 
    ["Brine Pool"] = {
        Trash = 29, 
        Common = 29, 
        Uncommon = 25, 
        Unusual = 23, 
        Rare = 15
    }
}
local v4 = {
    ["Meg's Spine"] = {
        WeightPool = {
            25, 
            50
        }, 
        Chance = 0.001, 
        Rarity = "Mythical", 
        Resilience = 100, 
        Description = "The Spine of the Apex Shark, Megalodon", 
        Hint = "Found in the Oceans of Ancient Isles...", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 1500, 
        XP = 250, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Found a Meg Spine!"
        }, 
        SparkleColor = Color3.fromRGB(33, 55, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "None"
    }, 
    ["Meg's Fang"] = {
        WeightPool = {
            10, 
            20
        }, 
        Chance = 0.001, 
        Rarity = "Mythical", 
        Resilience = 100, 
        Description = "The Fang of the Apex Shark, Megalodon", 
        Hint = "Found in the Oceans of Ancient Isles...", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 1500, 
        XP = 250, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Found a Meg Fang!"
        }, 
        SparkleColor = Color3.fromRGB(33, 55, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "None"
    }, 
    ["Moon Wood"] = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 10000, 
        Rarity = "Legendary", 
        Resilience = 100, 
        Description = "Legends say, Moon Wood is used in crafting one of the strongest Rods...", 
        Hint = "This resilient wood has endured the bitterest winters, its strength forged under the pale glow of the moon.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 450, 
        XP = 50, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, Moon Wood!"
        }, 
        SparkleColor = Color3.fromRGB(151, 255, 212), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    ["Inferno Wood"] = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 100, 
        Description = "Holds the Power of Earth's Magma Core... Said to be used in crafting one of the strongest Rods...", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 700, 
        XP = 90, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, Inferno Wood!"
        }, 
        SparkleColor = Color3.fromRGB(255, 129, 25), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    ["Ancient Wood"] = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 0.5, 
        Rarity = "Legendary", 
        Resilience = 100, 
        Description = "Reputed to harbor the essence of Ancient Wisdom, etched into the very grain of its timeless wood.", 
        Hint = "Legends whisper of Sunstone Island radiating an aura of ancient power", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 450, 
        XP = 50, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ancient Wood!"
        }, 
        SparkleColor = Color3.fromRGB(228, 255, 140), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    ["Void Wood"] = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 0.5, 
        Rarity = "Legendary", 
        Resilience = 100, 
        Description = "Believed to channel the mysteries of the Void, its wood pulses with an enigmatic, otherworldly energy.", 
        Hint = "Void Wood is said to be imbued with the altar's enigmatic power.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 350, 
        XP = 35, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "???"
        }, 
        SparkleColor = Color3.fromRGB(182, 65, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    Moonstone = {
        WeightPool = {
            5, 
            28
        }, 
        Chance = 0, 
        Rarity = "Gemstone", 
        Resilience = 100, 
        Description = "A white gemstone with a pearlescent shine, typically associated with magic.", 
        Hint = "From meteors.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 1000, 
        XP = 200, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Moonstone!"
        }, 
        SparkleColor = Color3.fromRGB(189, 235, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle", 
        FromMeteor = true, 
        Evaluation = "Moonstone's hard, ethereal glow\226\128\148caused by light scattering within its layers\226\128\148, often associated with the lunar energy from our lovely moon."
    }, 
    ["Lapis Lazuli"] = {
        WeightPool = {
            4, 
            14
        }, 
        Chance = 0, 
        Rarity = "Gemstone", 
        Resilience = 100, 
        Description = "A deep blue gemstone with a complex shape.", 
        Hint = "From meteors.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 700, 
        XP = 150, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu, shiny!"
        }, 
        SparkleColor = Color3.fromRGB(33, 55, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle", 
        FromMeteor = true, 
        Evaluation = "Lapis Lazuli has been ground into powder for use in luxurious paints and cosmetics for millennia, symbolizing royalty and spirituality."
    }, 
    Opal = {
        WeightPool = {
            9, 
            32
        }, 
        Chance = 100, 
        Rarity = "Gemstone", 
        Resilience = 100, 
        Description = "An iridescent gemstone with an array of different colors.", 
        Hint = "From meteors.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 500, 
        XP = 115, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu, shiny!"
        }, 
        SparkleColor = Color3.fromRGB(229, 229, 229), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle", 
        FromMeteor = true, 
        Evaluation = "Opals form in arid, sunstone soils, where water evaporates and leaves behind dazzling mineral deposits."
    }, 
    Ruby = {
        WeightPool = {
            7, 
            20
        }, 
        Chance = 0, 
        Rarity = "Gemstone", 
        Resilience = 100, 
        Description = "A gemstone with a very intense red hue.", 
        Hint = "From meteors.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 70, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu, shiny!"
        }, 
        SparkleColor = Color3.fromRGB(255, 29, 29), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle", 
        FromMeteor = true, 
        Evaluation = "Forming in marble or basalt environments under intense heat and pressure of Roslits Volcano. "
    }, 
    Amethyst = {
        WeightPool = {
            8, 
            16
        }, 
        Chance = 100, 
        Rarity = "Gemstone", 
        Resilience = 100, 
        Description = "A purple variety of quartz with calming properties.", 
        Hint = "From meteors.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 150, 
        XP = 35, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu, shiny!"
        }, 
        SparkleColor = Color3.fromRGB(157, 92, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle", 
        FromMeteor = true, 
        Evaluation = "Amethyst forms in volcanic rock cavities called geodes, where mineral-rich water deposits quartz crystals over time. It was once as valuable as diamonds and associated with preventing overindulgence."
    }, 
    ["Deep Sea Fragment"] = {
        WeightPool = {
            1, 
            1
        }, 
        Chance = 0, 
        Rarity = "Fragment", 
        Resilience = 100, 
        Description = "A magical stone with an etching representing the violent waves of the sea.", 
        Hint = "Long ago, this ancient fragment had flown away into the mythical waterfall of Ancient Isles", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 0, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ancient Isle"
    }, 
    ["Solar Fragment"] = {
        WeightPool = {
            1, 
            1
        }, 
        Chance = 0, 
        Rarity = "Fragment", 
        Resilience = 100, 
        Description = "A magical stone with an etching representing the scorching heat of the sun.", 
        Hint = "Only said to appear at the highest peaks during the Eclipse.", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 50, 
        XP = 10, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ancient Isle"
    }, 
    ["Earth Fragment"] = {
        WeightPool = {
            1, 
            1
        }, 
        Chance = 0, 
        Rarity = "Fragment", 
        Resilience = 100, 
        Description = "A magical stone with an etching representing the life on planet Earth.", 
        Hint = "Said to be lost in the caves of Ancient Isles...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 0, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ancient Isle"
    }, 
    ["Ancient Fragment"] = {
        WeightPool = {
            1, 
            1
        }, 
        Chance = 0.01, 
        Rarity = "Fragment", 
        Resilience = 100, 
        Description = "A magical stone with an etching representing a mystical sea creature lost in time.", 
        Hint = "Found in the oceans of Ancient Isles...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 500, 
        XP = 80, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ancient Isle"
    }, 
    Megalodon = {
        BlockPassiveCapture = true, 
        HideFishModel = true, 
        WeightPool = {
            500000, 
            670000
        }, 
        Chance = 0.01, 
        Rarity = "Exotic", 
        Resilience = 5, 
        ProgressEfficiency = 0.2, 
        Description = "The Megalodon is a gigantic predatory shark known for its enormous size. It possesses a large mouth with many serrated teeth which can easily rip through anything in its way. They went extinct around 3.6 million years ago, during the early Pliocene epoch. They are one of the apex predators of the Ancient Isle, and will put up an incredible fight when hooked.", 
        Hint = "???", 
        FavouriteBait = "Shark Head", 
        FavouriteTime = "None", 
        Price = 10000, 
        XP = 6000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH The Meg!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    ["Phantom Megalodon"] = {
        BlockPassiveCapture = true, 
        HideFishModel = true, 
        WeightPool = {
            500000, 
            670000
        }, 
        Chance = 1.0E-4, 
        Rarity = "Limited", 
        Resilience = 5, 
        ProgressEfficiency = 0.15, 
        Description = "The Phantom Meg is a spectral version of the ancient Megalodon, haunting the waters with an ethereal glow. Its serrated teeth remain just as fearsome, tearing through anything in its way. Though extinct for millions of years, this ghostly apex predator dominates the Ancient Isle and will challenge any angler brave enough to hook it.", 
        Hint = "The Phantom Meg only emerges during the eclipse & twilight hours of the celestial cycle, when the sun and moon align every seven days.", 
        FavouriteBait = "Shark Head", 
        FavouriteTime = "None", 
        Price = 20000, 
        XP = 12000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH THE PHANTOM MEG!"
        }, 
        SparkleColor = Color3.fromRGB(255, 0, 0), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    ["Ancient Megalodon"] = {
        BlockPassiveCapture = true, 
        HideFishModel = true, 
        WeightPool = {
            500000, 
            700000
        }, 
        Chance = 0.005, 
        Rarity = "Exotic", 
        Resilience = 5, 
        ProgressEfficiency = 0.2, 
        Description = "The Ancient Megalodon is a colossal predatory shark from prehistoric times, unmatched in size and ferocity. With its massive mouth and serrated teeth, it can effortlessly rip through any obstacle. A true apex predator of the Ancient Isle, it offers an incredible battle for those daring to catch it.", 
        Hint = "???", 
        FavouriteBait = "Shark Head", 
        FavouriteTime = "None", 
        Price = 16000, 
        XP = 9000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH THE ANCIENT MEG!"
        }, 
        SparkleColor = Color3.fromRGB(131, 255, 49), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    ["Barracuda's Spine"] = {
        WeightPool = {
            25, 
            50
        }, 
        Chance = 40, 
        Rarity = "Limited", 
        Resilience = 100, 
        Description = "The Barracuda's fearsome backbone.", 
        Hint = "Divers have found the Barracuda Spine quite often around Moosewood...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 50, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Fossil Fan"] = {
        WeightPool = {
            25, 
            50
        }, 
        Chance = 40, 
        Rarity = "Limited", 
        Resilience = 100, 
        Description = "An ancient, fan-shaped fossil etched with intricate patterns, a true underwater treasure.", 
        Hint = "This was last discovered near Moosewood...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 60, 
        XP = 22, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Claw Gill"] = {
        WeightPool = {
            15, 
            30
        }, 
        Chance = 40, 
        Rarity = "Limited", 
        Resilience = 100, 
        Description = "Are these Claws or are they gills? All we know is, these are remains from fish that went extinct long ago...", 
        Hint = "Legends say the fish these belong to once swam predominantly in ponds.", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 60, 
        XP = 22, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Spine Bone"] = {
        WeightPool = {
            30, 
            60
        }, 
        Chance = 30, 
        Rarity = "Limited", 
        Resilience = 100, 
        Description = "Seems like the Spine bone of a really large fish...", 
        Hint = "Dr. Finneus had mentioned discovering this earlier around Roslit...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 80, 
        XP = 35, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Spine Blade"] = {
        WeightPool = {
            30, 
            60
        }, 
        Chance = 12, 
        Rarity = "Limited", 
        Resilience = 100, 
        Description = "A sturdy vertebra from a long-lost fish, steeped in ancient mystery.", 
        Hint = "If the Spine Bone was found around Roslit... Could this be from the same zone?", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 100, 
        XP = 40, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Shark Fang"] = {
        WeightPool = {
            30, 
            50
        }, 
        Chance = 7, 
        Rarity = "Limited", 
        Resilience = 100, 
        Description = "A razor-sharp tooth from a fearsome predator, gleaming with primal power.", 
        Hint = "Legends say most ancient shark dwelled in the Oceans of Roslit...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 135, 
        XP = 50, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Nessie's Spine"] = {
        WeightPool = {
            40, 
            80
        }, 
        Chance = 3, 
        Rarity = "Limited", 
        Resilience = 100, 
        ProgressEfficiency = 0.9, 
        Description = "A mythical vertebra said to belong to the Nessie.", 
        Hint = "We haven't checked the Mushgroves yet... Could this be discovered there?", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 250, 
        XP = 90, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Spined Fin"] = {
        WeightPool = {
            20, 
            50
        }, 
        Chance = 1, 
        Rarity = "Limited", 
        Resilience = 100, 
        ProgressEfficiency = 0.9, 
        Description = "A jagged, bony fin from a formidable fish, crafted by nature for defense.", 
        Hint = "This appears to be something a fish from the coldest regions would rely on for survival...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 300, 
        XP = 120, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah a bone!"
        }, 
        SparkleColor = Color3.fromRGB(126, 124, 123), 
        FromLimited = "Archeological Site"
    }, 
    ["Ancient Serpent Spine"] = {
        WeightPool = {
            30, 
            80
        }, 
        Chance = 0.01, 
        Rarity = "Limited", 
        Resilience = 100, 
        ProgressEfficiency = 0.8, 
        Description = "A chilling relic of a fearsome, long-forgotten creature, radiating an aura of dread.", 
        Hint = "Legends say the Pirates had only ONCE ever caught this... No One else ever got to lay their hands on this fish...", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 800, 
        XP = 250, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH! ANCIENT SERPENT SPINE?!"
        }, 
        SparkleColor = Color3.fromRGB(126, 12, 12), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    ["Ancient Serpent Skull"] = {
        WeightPool = {
            50, 
            100
        }, 
        Chance = 0.005, 
        Rarity = "Limited", 
        Resilience = 100, 
        ProgressEfficiency = 0.8, 
        Description = "A haunting, bone-chilling relic from a monstrous, lost predator, shrouded in eerie mystery. Beware... Locals say the skull holds a haunting power...", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = "None", 
        Price = 1200, 
        XP = 400, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH ANCIENT SERPENT'S SKULL!"
        }, 
        SparkleColor = Color3.fromRGB(126, 12, 12), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "Archeological Site"
    }, 
    Palaeoniscus = {
        WeightPool = {
            25, 
            700
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 70, 
        Description = "Palaeoniscus is an ancient ray-finned fish from the Early Permian period, approximately 290 million years ago. Known for its robust ganoid scales and streamlined body, it represents early actinopterygian evolution, the ancestor of most modern fish.", 
        Hint = "Found within the Ancient Isle's waterfall.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 125, 
        XP = 35, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Palaeoniscus!", 
            "OMG A Palaeoniscus!", 
            "I can't believe I caught a Palaeoniscus!"
        }, 
        SparkleColor = Color3.fromRGB(33, 106, 122), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ancient Archives"
    }, 
    Birgeria = {
        WeightPool = {
            500, 
            1200
        }, 
        Chance = 15, 
        Rarity = "Unusual", 
        Resilience = 55, 
        Description = "Birgeria is a genus of extinct fish from the Late Triassic period, recognized for its large size and long, slender body. It was a carnivorous predator that roamed ancient seas, hunting smaller fish and invertebrates.", 
        Hint = "Found in the dark waters of the Archives...", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 200, 
        XP = 60, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Birgeria!", 
            "OMG A Birgeria!", 
            "Look at this, a Birgeria!"
        }, 
        SparkleColor = Color3.fromRGB(200, 200, 200), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Archives"
    }, 
    Phanerorhynchus = {
        WeightPool = {
            600, 
            1400
        }, 
        Chance = 3, 
        Rarity = "Rare", 
        Resilience = 40, 
        Description = "Phanerorhynchus is an extinct, predatory fish from the Late Devonian period. Known for its elongated body and sharp, backward-curving teeth, it was a formidable predator in ancient aquatic ecosystems.", 
        Hint = "Found in the dark waters of the Archives...", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 450, 
        XP = 90, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Phanerorhynchus!", 
            "OMG A Phanerorhynchus!", 
            "Wow, a Phanerorhynchus!"
        }, 
        SparkleColor = Color3.fromRGB(102, 51, 0), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Archives"
    }, 
    Diplurus = {
        WeightPool = {
            800, 
            1600
        }, 
        Chance = 0.1, 
        Rarity = "Legendary", 
        Resilience = 30, 
        Description = "Diplurus is an extinct fish from the Late Devonian period, distinguished by its unique, two-lobed tail. It was an active predator, preying on smaller fish and invertebrates in ancient freshwater habitats.", 
        Hint = "Found in the dark waters of the Archives...", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Day", 
        Price = 800, 
        XP = 250, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Diplurus!", 
            "OMG A Diplurus!", 
            "I can't believe I caught a Diplurus!"
        }, 
        SparkleColor = Color3.fromRGB(153, 102, 0), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Archives"
    }, 
    Lepidotes = {
        WeightPool = {
            900, 
            2000
        }, 
        Chance = 0.03, 
        Rarity = "Mythical", 
        Resilience = 20, 
        Description = "Lepidotes is an extinct fish from the Mesozoic era. Known for its large, heavily armored body and prominent fin structure, it was a significant predator in ancient oceans.", 
        Hint = "Found in the dark waters of the Archives...", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 1800, 
        XP = 500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Lepidotes!", 
            "OMG A Lepidotes!", 
            "I can't believe I caught a Lepidotes!"
        }, 
        SparkleColor = Color3.fromRGB(255, 215, 0), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Archives"
    }, 
    Amblypterus = {
        WeightPool = {
            700, 
            1800
        }, 
        Chance = 0.005, 
        Rarity = "Mythical", 
        Resilience = 15, 
        Description = "Amblypterus is an extinct genus of prehistoric fish from the Carboniferous period, known for its unusual body shape and large, complex pectoral fins that allowed for agile, precise movement.", 
        Hint = "Found in the dark waters of the Archives...", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Day", 
        Price = 2500, 
        XP = 700, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught an Amblypterus!", 
            "OMG A Amblypterus!", 
            "I can't believe I caught an Amblypterus!"
        }, 
        SparkleColor = Color3.fromRGB(204, 153, 0), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Archives"
    }, 
    ["The Depths Key"] = {
        WeightPool = {
            500, 
            1000
        }, 
        Chance = 0.01, 
        Rarity = "Exotic", 
        Resilience = 35, 
        ProgressEfficiency = 0.9, 
        Description = "This is the Key that leads to the gates of The Depths...", 
        Hint = "Where does this key open up?...", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 800, 
        XP = 350, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a depths key!", 
            "Woah, a key!!"
        }, 
        SparkleColor = Color3.fromRGB(126, 12, 12), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Vertigo"
    }, 
    ["Destroyed Fossil"] = {
        WeightPool = {
            10, 
            45
        }, 
        Chance = 35, 
        Rarity = "Trash", 
        Resilience = 100, 
        Description = "A Destroyed Fossil... How much would this sell for?", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 35, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Oh... A Destroyed Fossil?"
        }, 
        SparkleColor = Color3.fromRGB(126, 116, 78), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "The Depths"
    }, 
    ["Scrap Metal"] = {
        WeightPool = {
            10, 
            50
        }, 
        Chance = 32, 
        Rarity = "Trash", 
        Resilience = 100, 
        Description = "Just a piece of metal.", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 40, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Just a piece of scrap metal!"
        }, 
        SparkleColor = Color3.fromRGB(125, 126, 123), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "The Depths"
    }, 
    ["Deep-sea Hatchetfish"] = {
        WeightPool = {
            5, 
            35
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 90, 
        Description = "A small, silvery fish with sharp edges and glowing organs, resembling a metallic hatchet.", 
        Hint = "Dwells during the Night, near steep underwater cliffs.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Night", 
        Price = 35, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ooh, a Deep Sea Hatchetfish!"
        }, 
        SparkleColor = Color3.fromRGB(99, 97, 126), 
        HoldAnimation = l_fish_0:WaitForChild("bigbasic"), 
        From = "The Depths"
    }, 
    ["Deep-sea Dragonfish"] = {
        WeightPool = {
            8, 
            40
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "A bioluminescent predator with sharp fangs, glowing lure, and stealthy camouflage in ocean depths.", 
        Hint = "Lurks deep in shadowy trenches during the Night", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 45, 
        XP = 25, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Oh, a Deep sea Dragonfish!"
        }, 
        SparkleColor = Color3.fromRGB(73, 74, 126), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "The Depths"
    }, 
    ["Luminescent Minnow"] = {
        WeightPool = {
            2, 
            8
        }, 
        Chance = 60, 
        Rarity = "Unusual", 
        Resilience = 80, 
        Description = "A tiny, glowing fish that sparkles like a gem, illuminating the dark waters.", 
        Hint = "Found in shallow caves under glowing coral clusters.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Night", 
        Price = 120, 
        XP = 30, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "What is that glowing fish..."
        }, 
        SparkleColor = Color3.fromRGB(41, 150, 172), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "The Depths"
    }, 
    ["Frilled Shark"] = {
        WeightPool = {
            40, 
            90
        }, 
        Chance = 50, 
        Rarity = "Unusual", 
        Resilience = 70, 
        Description = "A serpentine predator with a ruffled neck and razor-sharp teeth, ancient and elusive.", 
        Hint = "Hides in deep ocean caves near rocky crevices, appears during the Nigh time.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 150, 
        XP = 45, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "That's a large frilled shark!"
        }, 
        SparkleColor = Color3.fromRGB(65, 93, 64), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "The Depths"
    }, 
    ["Depth Octopus"] = {
        WeightPool = {
            30, 
            80
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 50, 
        Description = "A mysterious, translucent octopus with glowing spots and a knack for stealthy escapes.", 
        Hint = "Lurks in deep, dark waters in the Depth.", 
        FavouriteBait = "Coral", 
        FavouriteTime = "Day", 
        Price = 175, 
        XP = 50, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, that's almost transparent, what is it??"
        }, 
        SparkleColor = Color3.fromRGB(125, 126, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "The Depths"
    }, 
    ["Three-eyed Fish"] = {
        WeightPool = {
            20, 
            60
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 70, 
        Description = "A mutant fish with three glowing eyes, sleek scales, and a bizarre, eerie charm.", 
        Hint = "Swims during the dark night and underwater ruins.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Night", 
        Price = 200, 
        XP = 55, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah! The Three Eyed Fish!"
        }, 
        SparkleColor = Color3.fromRGB(125, 126, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "The Depths"
    }, 
    ["Goblin Shark"] = {
        WeightPool = {
            200, 
            450
        }, 
        Chance = 25, 
        Rarity = "Rare", 
        Resilience = 50, 
        Description = "A deep-sea predator with a protruding snout, jagged teeth, and a ghostly appearance.", 
        Hint = "Roams trench edges and dark underwater canyons.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 450, 
        XP = 80, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Wow, that's a Goblin Shark?"
        }, 
        SparkleColor = Color3.fromRGB(76, 126, 44), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Black Dragon Fish"] = {
        WeightPool = {
            150, 
            400
        }, 
        Chance = 10, 
        Rarity = "Rare", 
        Resilience = 45, 
        Description = "A menacing fish with sharp fins and an eerie, black-scaled body.", 
        Hint = "Found in the deepest ocean trenches, far from light.", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 500, 
        XP = 120, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "THE Black Dragon Fish?!"
        }, 
        SparkleColor = Color3.fromRGB(126, 59, 59), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Spider Crab"] = {
        WeightPool = {
            80, 
            250
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 60, 
        Description = "A large, eerie crab with long, spindly legs and a tough, armoured shell.", 
        Hint = "Can be found during the day through fishing or inside crab cages.", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Day", 
        Price = 550, 
        XP = 135, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Is that a Spider.. Or a Crab??"
        }, 
        SparkleColor = Color3.fromRGB(125, 126, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "The Depths"
    }, 
    Nautilus = {
        WeightPool = {
            400, 
            800
        }, 
        Chance = 0.2, 
        Rarity = "Legendary", 
        Resilience = 30, 
        ProgressEfficiency = 0.9, 
        Description = "An ancient, spiral-shelled mollusc with a glowing & graceful body, tentacle-filled movements. The Nautilus is an elusive octopus that creates a thick, spiral-shaped shell around its body for protection.", 
        Hint = "Dwells in deep coral reefs and rocky underwater caves, mostly visible during the Night.", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 1000, 
        XP = 300, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Nautilus... OMG!!"
        }, 
        SparkleColor = Color3.fromRGB(203, 174, 139), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Small Spine Chimera"] = {
        WeightPool = {
            800, 
            1500
        }, 
        Chance = 0.2, 
        Rarity = "Legendary", 
        Resilience = 10, 
        ProgressEfficiency = 0.9, 
        Description = "A large, intimidating fish with spiny fins, sharp teeth, and a menacing, serpent-like body. The Chimera uses its pickaxe-like bill to strike targets, knocking them out or possible penetrating them entirely in two pieces.", 
        Hint = "Roams the deep ocean, patrolling sunken ruins and underwater trenches.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Day", 
        Price = 1200, 
        XP = 300, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, a small spine chimera!"
        }, 
        SparkleColor = Color3.fromRGB(125, 126, 123), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Ancient Eel"] = {
        WeightPool = {
            1000, 
            2000
        }, 
        Chance = 0.4, 
        Rarity = "Legendary", 
        Resilience = 10, 
        ProgressEfficiency = 0.7, 
        Description = "A long, snake-like eel with glowing patterns and a menacing, ancient presence. This is one of the oldest creatures known to man, with it dating back to 3400 BCE.", 
        Hint = "Found in deep ocean caves during the Night.", 
        FavouriteBait = "Coal", 
        FavouriteTime = "Night", 
        Price = 1500, 
        XP = 350, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A-A-Ancient Eel?!"
        }, 
        SparkleColor = Color3.fromRGB(51, 37, 126), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Mutated Shark"] = {
        WeightPool = {
            2000, 
            4000
        }, 
        Chance = 0.05, 
        Rarity = "Mythical", 
        Resilience = 20, 
        ProgressEfficiency = 0.8, 
        Description = "A massive, mutated shark with glowing scars, extra fins, and an unsettling, aggressive nature. While it's named suggests it being a shark, it is actually more related to alligators. Using it's sleek body and its strong legs to pounce on unsuspecting prey.", 
        Hint = "Patrols the darkest depths during the Coldest Nights...", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 3000, 
        XP = 800, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Does that thing really have legs?!"
        }, 
        SparkleColor = Color3.fromRGB(102, 126, 57), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Barreleye Fish"] = {
        WeightPool = {
            50, 
            150
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 20, 
        ProgressEfficiency = 0.85, 
        Description = "A transparent fish with a dome-shaped head and large, upward-facing eyes, adapted for deep waters with it's 3 eyes. The third eye has a similar effect that night-vision goggles have, giving it full 20/20 vision, even in the darkest of waters.", 
        Hint = "Found in the deep ocean during the Night, drifting near bioluminescent creatures.", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 4500, 
        XP = 950, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "That fish is translucent, beautiful..."
        }, 
        SparkleColor = Color3.fromRGB(91, 126, 104), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "The Depths"
    }, 
    ["Sea Snake"] = {
        WeightPool = {
            300, 
            800
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 10, 
        ProgressEfficiency = 0.6, 
        Description = "A long, venomous sea snake with smooth, scaly skin and a graceful, undulating movement.", 
        Hint = "Swims near coral reefs and sunken ruins in shallow waters during the cold nights.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 5000, 
        XP = 1200, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOW! A SEA SNAKE!"
        }, 
        SparkleColor = Color3.fromRGB(126, 53, 104), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Ancient Depth Serpent"] = {
        WeightPool = {
            5000, 
            10000
        }, 
        Chance = 0.01, 
        Rarity = "Exotic", 
        Resilience = 2, 
        ProgressEfficiency = 0.4, 
        Description = "A colossal, serpent-like creature with armored scales and glowing eyes, lurking in the abyss. The Ancient Depth Serpent is only active when The Depths go completely dark... No one knows where it goes in the meantime, possibly lurking in a secret cave?", 
        Hint = "Dwells in the deepest trenches, guarding forgotten underwater ruins. Appears only during the darkest of nights...", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = "Night", 
        Price = 8000, 
        XP = 2200, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "OMG. THATS THE ANCIENT DEPTH SERPENT!!!"
        }, 
        SparkleColor = Color3.fromRGB(28, 255, 100), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "The Depths"
    }, 
    ["Corsair Grouper"] = {
        WeightPool = {
            50, 
            200
        }, 
        Chance = 120, 
        Rarity = "Common", 
        Resilience = 100, 
        Description = "The Corsair Grouper is a resilient, bulky fish, often hiding among shores. Known for its powerful bites, it\226\128\153s a decent challenge for beginners.", 
        Hint = "commonly caught in Forsaken Shores.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Day", 
        Price = 35, 
        XP = 30, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Corsair Grouper!", 
            "Woah, a Corsair Grouper!!"
        }, 
        SparkleColor = Color3.fromRGB(125, 126, 123), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Shortfin Mako Shark"] = {
        WeightPool = {
            250, 
            1000
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Shortfin Mako is a fast predator found in the forsaken ocean. Its speed and strength attract seasoned anglers.", 
        Hint = "commonly caught in Forsaken Shores surrounding Ocean.", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 190, 
        XP = 70, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "WOAH! A SHORTFINNED MAKO!", 
            "OMG, IS THAT A SHORTFIN MAKO?"
        }, 
        SparkleColor = Color3.fromRGB(70, 76, 126), 
        HoldAnimation = l_fish_0:WaitForChild("bigbasic"), 
        From = "Forsaken Shores"
    }, 
    ["Galleon Goliath"] = {
        WeightPool = {
            50, 
            200
        }, 
        Chance = 70, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "The Galleon Goliath is a mid-sized, slow-moving fish, often found in deeper seas. Uncommon but worth the haul.", 
        Hint = "Often found in deeper seas near Forsaken Shores.", 
        FavouriteBait = "Squid", 
        FavouriteTime = "Day", 
        Price = 190, 
        XP = 85, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH! A GALLEON GOLIATH!", 
            "OMG, IS THAT A GALLEON GOLIATH?"
        }, 
        SparkleColor = Color3.fromRGB(170, 170, 127), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Buccaneer Barracuda"] = {
        WeightPool = {
            90, 
            250
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 50, 
        Description = "Known for its sharp teeth, the Buccaneer Barracuda lurks near reefs, making it a thrilling catch for the daring.", 
        Hint = "Lurks near reefs during the Night & when it's cold.", 
        FavouriteBait = "Deep Coral", 
        FavouriteTime = "Night", 
        Price = 250, 
        XP = 100, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH! A BUCCANEER BARRACUDA!", 
            "OMG, IS THAT A BUCCANEER BARRACUDA?", 
            "NO WAY!!"
        }, 
        SparkleColor = Color3.fromRGB(85, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Scurvy Sailfish"] = {
        WeightPool = {
            150, 
            700
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 30, 
        Description = "Scurvy Sailfish are swift and skilled jumpers, often found near rocky shores. Their agility makes them hard to land.", 
        Hint = "Often found near rocky shores.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Night", 
        Price = 300, 
        XP = 140, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Yooo, is that a Sailfish?!"
        }, 
        SparkleColor = Color3.fromRGB(0, 85, 127), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Cutlass Fish"] = {
        WeightPool = {
            80, 
            250
        }, 
        Chance = 50, 
        Rarity = "Unusual", 
        Resilience = 40, 
        Description = "The sleek Cutlass Fish glides through reefs, known for its long, blade-like body. Easy to spot, harder to hook.", 
        Hint = "commonly caught in Forsaken Shores.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 500, 
        XP = 175, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Yooo, is that THE Cutlass Fish?!"
        }, 
        SparkleColor = Color3.fromRGB(0, 85, 127), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Reefrunner Snapper"] = {
        WeightPool = {
            80, 
            250
        }, 
        Chance = 35, 
        Rarity = "Rare", 
        Resilience = 25, 
        ProgressEfficiency = 0.7, 
        Description = "Bold yet wary, the Reefunner Snapper darts around reefs. A popular, rare catch for reef fishers.", 
        Hint = "commonly caught in Forsaken Shores.", 
        FavouriteBait = "Insect", 
        FavouriteTime = "Day", 
        Price = 750, 
        XP = 200, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Yooo, that's a Reefrunner!"
        }, 
        SparkleColor = Color3.fromRGB(246, 126, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Cursed Eel"] = {
        WeightPool = {
            80, 
            250
        }, 
        Chance = 25, 
        Rarity = "Rare", 
        Resilience = 15, 
        ProgressEfficiency = 0.5, 
        Description = "Cursed Eels linger in darker waters, giving off an eerie glow. They\226\128\153re a spooky find for night anglers.", 
        Hint = "Found in darker waters in the oceanside.", 
        FavouriteBait = "Coal", 
        FavouriteTime = "Night", 
        Price = 700, 
        XP = 250, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Cursed Eel!", 
            "Am I gonna get shocked?!"
        }, 
        SparkleColor = Color3.fromRGB(61, 119, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Shipwreck Barracuda"] = {
        WeightPool = {
            100, 
            300
        }, 
        Chance = 0.1, 
        Rarity = "Legendary", 
        Resilience = 10, 
        Description = "Lurking near old wrecks, the Shipwreck Barracuda guards sunken treasure spots. Feared by some, prized by others.", 
        Hint = "Lurking near old wrecks in the Forsaken Ocean.", 
        FavouriteBait = "Coral", 
        FavouriteTime = "Night", 
        Price = 1200, 
        XP = 400, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Yooo, that's a Shipwreck Barracuda!"
        }, 
        SparkleColor = Color3.fromRGB(255, 25, 113), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Forsaken Shores"
    }, 
    ["Golden Seahorse"] = {
        WeightPool = {
            3, 
            8
        }, 
        Chance = 0.001, 
        Rarity = "Mythical", 
        Resilience = 10, 
        Description = "Golden Sea Horses are small but enchanting, drifting near seaweed & algae. Gentle and rare, they\226\128\153re a delight to find.", 
        Hint = "Drifting near seaweed & algae in the Oceanside.", 
        FavouriteBait = "Weird Algae", 
        FavouriteTime = "Day", 
        Price = 2900, 
        XP = 2800, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "IS THAT A GOLDEN SEAHORSE?!"
        }, 
        SparkleColor = Color3.fromRGB(243, 255, 14), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Forsaken Shores"
    }, 
    ["Captain's Goldfish"] = {
        WeightPool = {
            10, 
            25
        }, 
        Chance = 0.001, 
        Rarity = "Mythical", 
        Resilience = 5, 
        Description = "A mythical, elusive goldfish found beneath waterfalls, said to bring fortune to rare finders.", 
        Hint = "Found beneath enchanted waterfalls.", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = "Day", 
        Price = 1700, 
        XP = 2800, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "IS THAT A CAPTAIN GOLDFISH?!"
        }, 
        SparkleColor = Color3.fromRGB(243, 255, 14), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Forsaken Shores"
    }, 
    Piranha = {
        WeightPool = {
            20, 
            50
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 70, 
        Description = "Piranhas are aggressive fish with incredibly sharp teeth, which they use to hunt their prey. Ranking high on the local food chain, they are still no match for the larger and fiercer apex predators of the Ancient Isle.", 
        Hint = "Can be found in the waters of the Ancient Isle.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 85, 
        XP = 95, 
        Seasons = {
            "Spring", 
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Piranha!", 
            "I caught a Piranha!", 
            "Woah! A Piranha!", 
            "Ouu! A Piranha!", 
            "It bit me!"
        }, 
        SparkleColor = Color3.fromRGB(255, 137, 69), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle"
    }, 
    Cladoselache = {
        WeightPool = {
            180, 
            240
        }, 
        Chance = 87, 
        Rarity = "Common", 
        Resilience = 70, 
        Description = "Cladoselache is a sleek, agile predator from the Devonian era, hunting fish and cephalopods.", 
        Hint = "Can be found in freshwater in the Ancient Isle.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 90, 
        XP = 95, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Cladoselache!", 
            "I caught a Cladoselache!", 
            "Woah! A Cladoselache!", 
            "Ouu! A Cladoselache!"
        }, 
        SparkleColor = Color3.fromRGB(255, 137, 69), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    Anomalocaris = {
        WeightPool = {
            100, 
            400
        }, 
        Chance = 65, 
        Rarity = "Uncommon", 
        Resilience = 65, 
        Description = "The Anomalocaris is a large predator of the Ancient Isle. They flex their fins in a wave-like motion to generate speed, which they use to pursue prey. They bear strong armor-like scales on their backs, making them quite strong. The Anomalocaris went extinct around 485 million years ago at the end of the Ordovician period.", 
        Hint = "Found around the Ancient Isle.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Night", 
        Price = 90, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu an Anomalocaris!", 
            "Woah, an Anomalocaris!", 
            "An Anomalocaris!", 
            "I caught an Anomalocaris!"
        }, 
        SparkleColor = Color3.fromRGB(204, 64, 80), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ancient Isle"
    }, 
    Starfish = {
        WeightPool = {
            20, 
            70
        }, 
        Chance = 55, 
        Rarity = "Uncommon", 
        Resilience = 95, 
        Description = "The starfish is a marine invertebrate with five arms that have hundreds of little feet which they use to move around. They prey on small organisms in their habitats, and are usually out and about during the daytime.", 
        Hint = "Found at the Ancient Isle.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 110, 
        XP = 115, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Starfish!", 
            "Woah, a Starfish!", 
            "A Starfish!", 
            "I caught a Starfish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 177, 51), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle"
    }, 
    Onychodus = {
        WeightPool = {
            1000, 
            1400
        }, 
        Chance = 55, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "Onychodus is a genus of prehistoric lobe-finned fish from the Devonian period, approximately 400 million years ago. Known for its distinctive features, Onychodus was an early example of sarcopterygian fish, which includes ancestors of modern lungfish and tetrapods.", 
        Hint = "Found around the waters of the Ancient Isle.", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 115, 
        XP = 110, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu an Onychodus!", 
            "Woah, an Onychodus!", 
            "An Onychodus!", 
            "I caught an Onychodus!"
        }, 
        SparkleColor = Color3.fromRGB(82, 94, 204), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "Ancient Isle"
    }, 
    Acanthodii = {
        WeightPool = {
            130, 
            160
        }, 
        Chance = 41, 
        Rarity = "Unusual", 
        Resilience = 70, 
        Description = "Acanthodii, commonly known as Spiny Sharks, possess many scales that form a diamond pattern along its body. They prey on smaller creatures among the Ancient Isle's waters, and are active both during the day and night. They went extinct around 250 million years ago, at the end of the Permian period.", 
        Hint = "Can be found in the waters of the Ancient Isle.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 160, 
        XP = 130, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu an Acanthodii!", 
            "Woah, an Acanthodii!", 
            "Acanthodiiiiiiiiiiiiiii!!!"
        }, 
        SparkleColor = Color3.fromRGB(255, 230, 190), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ancient Isle"
    }, 
    Xiphactinus = {
        WeightPool = {
            1400, 
            2000
        }, 
        Chance = 45, 
        Rarity = "Unusual", 
        Resilience = 60, 
        Description = "Xiphactinus is a massive, fast predator from the Cretaceous, with sharp teeth, sleek body, and incredible hunting efficiency.", 
        Hint = "Can be found all around the Ancient Isle.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 170, 
        XP = 135, 
        Seasons = {
            "Fall", 
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Xiphactinus!", 
            "Woah, a Xiphactinus!", 
            "A Xiphactinus!"
        }, 
        SparkleColor = Color3.fromRGB(96, 130, 33), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    Hyneria = {
        WeightPool = {
            10000, 
            18000
        }, 
        Chance = 30, 
        Rarity = "Unusual", 
        Resilience = 75, 
        Description = "Hyneria is a giant, predatory lobe-finned fish from the Devonian, ambushing prey with powerful jaws, sharp teeth, and remarkable swimming agility.", 
        Hint = "Can be found in the waters of the Ancient Isle.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 145, 
        XP = 120, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Ouu a Hyneria!", 
            "Woah, a Hyneria!", 
            "Hyneria!!!"
        }, 
        SparkleColor = Color3.fromRGB(114, 227, 140), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ancient Isle"
    }, 
    Hallucigenia = {
        WeightPool = {
            30, 
            100
        }, 
        Chance = 30, 
        Rarity = "Rare", 
        Resilience = 75, 
        Description = "The Hallucigenia is an elongated, worm-like creature with spiney appendages throughout its body. They went extinct around 485 million years ago, at the end of the Ordovician period. They are quite low on the food chain, primarily feeding on small microorganisms.", 
        Hint = "Can be found in freshwater at the Ancient Isle.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 200, 
        XP = 125, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Hallucigenia!", 
            "I caught a Hallucigenia!", 
            "Woah! A Hallucigenia!", 
            "Ouu! A Hallucigenia!"
        }, 
        SparkleColor = Color3.fromRGB(255, 160, 160), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle"
    }, 
    Cobia = {
        WeightPool = {
            400, 
            700
        }, 
        Chance = 25, 
        Rarity = "Rare", 
        Resilience = 55, 
        Description = "The Cobia is a long fish with dark scales throughout the top half of its body, and a lighter underbelly. The torpedo-shaped structure it possesses allows it to dart towards any prey, or swiftly evade larger predators. They feed on smaller fish during the day, and lurk near cover during the night. Their dark body provides nocturnal camoflauge to stay hidden from any nearby prey or predators.", 
        Hint = "Found around the Ancient Isle.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 230, 
        XP = 140, 
        Seasons = {
            "Summer", 
            "Autumn"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Cobia!", 
            "I caught a Cobia!", 
            "Woah! a Cobia!", 
            "COBIA!!!", 
            "A Cobia?!", 
            "That's a big Cobia!"
        }, 
        SparkleColor = Color3.fromRGB(74, 84, 132), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ancient Isle"
    }, 
    Floppy = {
        WeightPool = {
            80, 
            100
        }, 
        Chance = 0.05, 
        Rarity = "Legendary", 
        Resilience = 25, 
        ProgressEfficiency = 0.9, 
        Description = "The Floppy is an interesting fish in the Ancient Isle. Exhibiting signs of intense energy, attempting to catch the Floppy will not be an easy task. They spend most of the day swimming around the pond, ", 
        Hint = "Can be found in the waters of the Ancient Isle.", 
        FavouriteBait = "Super Flakes", 
        FavouriteTime = nil, 
        Price = 2000, 
        XP = 1200, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Floppy!", 
            "I caught a Floppy!", 
            "Woah! A Floppy!", 
            "Ouu! A Floppy!"
        }, 
        SparkleColor = Color3.fromRGB(255, 161, 78), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ancient Isle"
    }, 
    Leedsichthys = {
        WeightPool = {
            9000, 
            11000
        }, 
        Chance = 0.25, 
        Rarity = "Legendary", 
        Resilience = 30, 
        ProgressEfficiency = 0.75, 
        Description = "Leedsichthys is a colossal, plankton-feeding fish from the Jurassic period, approximately 165\226\128\147150 million years ago. It is one of the largest fish ever to exist, showcasing the diversity of prehistoric marine life.", 
        Hint = "Can be found in the waterfalls on the Ancient Isle.", 
        FavouriteBait = "Squid", 
        FavouriteTime = "Day", 
        Price = 2200, 
        XP = 1500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Woah, I caught a Leedsichthys!", 
            "A Leedsichthys!", 
            "Ouu, a Leedsichthys!", 
            "This thing's massive!"
        }, 
        SparkleColor = Color3.fromRGB(150, 229, 207), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    ["Ginsu Shark"] = {
        WeightPool = {
            7800, 
            10000
        }, 
        Chance = 0.13, 
        Rarity = "Legendary", 
        Resilience = 20, 
        ProgressEfficiency = 0.8, 
        Description = "The Ginsu Shark, a powerful Cretaceous predator, uses sharp serrated teeth and sleek speed to hunt large fish, marine reptiles, and other sharks.", 
        Hint = "Can be found in the waters of the Ancient Isle.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 3000, 
        XP = 1800, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Summer"
        }, 
        Quips = {
            "Woah, I caught a Ginsu Shark!", 
            "A Ginsu Shark!", 
            "No way! A Ginsu Shark!", 
            "Ouuu, a Ginsu Shark!", 
            "No way! A Ginsu Shark!"
        }, 
        SparkleColor = Color3.fromRGB(129, 143, 165), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    Dunkleosteus = {
        WeightPool = {
            12000, 
            30000
        }, 
        Chance = 0.09, 
        Rarity = "Legendary", 
        Resilience = 30, 
        ProgressEfficiency = 0.65, 
        Description = "The Dunkleosteus is a large predatory fish, bearing an armored skull and jaw. Its reinforced exoskull gives it the ability to easily crush any prey to bits. They went extinct around 360 million years ago, during the Late Devonian period.", 
        Hint = "Can be found in the waters of the Ancient Isle.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Day", 
        Price = 3500, 
        XP = 2000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, I caught a Dunkleosteus!", 
            "A Dunkleosteus!", 
            "No way! A Dunkleosteus!"
        }, 
        SparkleColor = Color3.fromRGB(80, 80, 118), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    Helicoprion = {
        WeightPool = {
            2500, 
            4200
        }, 
        Chance = 0.03, 
        Rarity = "Mythical", 
        Resilience = 20, 
        ProgressEfficiency = 0.3, 
        Description = "Helicoprion is a prehistoric shark with a unique, spiral tooth structure, using its powerful jaws to capture prey in the Ancient isles shallow seas.", 
        Hint = "???", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 6000, 
        XP = 2500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "WOAH! A HELICOPRION!!", 
            "NO WAY!!", 
            "I CAUGHT A HELICOPRION!!", 
            "IT'S A HELICOPRION!"
        }, 
        SparkleColor = Color3.fromRGB(169, 225, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    Mosasaurus = {
        WeightPool = {
            90000, 
            140000
        }, 
        Chance = 0.015, 
        Rarity = "Mythical", 
        Resilience = 25, 
        ProgressEfficiency = 0.25, 
        Description = "Mosasaurus is the type genus of the mosasaurs, an extinct group of aquatic squamate reptiles. It exists from about 82 to 66 million years ago during the Campanian and Maastrichtian stages of the Late Cretaceous.", 
        Hint = "???", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = "Night", 
        Price = 7500, 
        XP = 3000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "WOAH! A MOSASAURUS!!", 
            "NO WAY!!", 
            "I CAUGHT A MOSASAURUS!!", 
            "IT'S A MOSASAURUS!", 
            "A DINO!!"
        }, 
        SparkleColor = Color3.fromRGB(121, 176, 91), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ancient Isle"
    }, 
    Tire = {
        WeightPool = {
            110, 
            110
        }, 
        Chance = 17, 
        Rarity = "Trash", 
        Resilience = 130, 
        Description = "Who would leave this in an ocean? Seems to be in great condition too. A common tire for cars and pickup trucks.", 
        Hint = "Find it in cheap bodies of water.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 20, 
        XP = 10, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "A tire.?", 
            "Who would put this in here?", 
            "Oh. A tire.", 
            "A tire!..?"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "None"
    }, 
    Boot = {
        WeightPool = {
            12, 
            12
        }, 
        Chance = 17, 
        Rarity = "Trash", 
        Resilience = 120, 
        Description = "Who would leave this in an ocean? Seems to be in great condition too. A common boot, must of fallen off of a boat?.. Or Someone must of fallen off of a boat.. Whatever. either way, it's yours now!", 
        Hint = "Find it in cheap bodies of water.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 15, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "Why only one..?", 
            "A Boot.!", 
            "A Boot...", 
            "I caught!.. a Boot..?", 
            "Erm.. A Boot?"
        }, 
        SparkleColor = Color3.fromRGB(197, 152, 80), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    Driftwood = {
        WeightPool = {
            6, 
            6
        }, 
        Chance = 17, 
        Rarity = "Trash", 
        Resilience = 120, 
        Description = "A wood that has been washed up onto the shore by the tides. Could be great for a crafts project!", 
        Hint = "Find it washed on beaches.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 10, 
        XP = 30, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "Uhmm..?", 
            "Driftwood!", 
            "Oh. Driftwood.", 
            "It's!- Oh.. Driftwood..", 
            "Driftwood.."
        }, 
        SparkleColor = Color3.fromRGB(197, 107, 62), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    Seaweed = {
        WeightPool = {
            1, 
            3
        }, 
        Chance = 20, 
        Rarity = "Trash", 
        Resilience = 90, 
        Description = "Some lovely seaweed that caught your hook. Not as cool as a fish, but it's better than finding a lonesome boot!", 
        Hint = "Find it in saltwater or near patches of seaweed.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 9, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Seaweed!", 
            "Oh. Seaweed.", 
            "It's!- Oh.. Seaweed..", 
            "Seaweed.."
        }, 
        SparkleColor = Color3.fromRGB(197, 107, 62), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    Log = {
        WeightPool = {
            45, 
            75
        }, 
        Chance = 10, 
        Rarity = "Trash", 
        Resilience = 80, 
        Description = "A large log of wood than must have drifted on to shore. Could be great for house projects!", 
        Hint = "Find it washed on beaches and in the ocean.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 124, 
        XP = 45, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Oh.. a Log!", 
            "A.. Log?", 
            "How did I pull this up?", 
            "A Log..?"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "None"
    }, 
    Rock = {
        WeightPool = {
            150, 
            210
        }, 
        Chance = 50, 
        Rarity = "Trash", 
        Resilience = 90, 
        Description = "It's not a boulder.. It's a rock! Found in rocky bodies of water.", 
        Hint = "Found in rocky bodies of water.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 15, 
        XP = 10, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "Uhmm..?", 
            "A Rock!", 
            "Oh. A Rock.", 
            "It's!- Oh.. A Rock..", 
            "A rock.."
        }, 
        SparkleColor = Color3.fromRGB(80, 80, 80), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "None"
    }, 
    ["Common Crate"] = {
        WeightPool = {
            80, 
            80
        }, 
        Chance = 17, 
        Rarity = "Uncommon", 
        Resilience = 120, 
        Description = "A moderately sized wooden crate seemingly lost from a fishing boat of some kind. The date of it's disappearance is unknown. Therefore, finders keepers?- Opening it might give you an array of fish, bait, and money!", 
        Hint = "Fallen off of a fishing boat.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        BuyMult = 1.6, 
        Price = 80, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Common Crate!", 
            "A Crate!", 
            "Woah! A Crate!", 
            "A Common Crate!", 
            "Who left this here?"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("crate"), 
        IsCrate = true, 
        CrateType = "All", 
        BaitContents = {
            "Shrimp", 
            "Bagel", 
            "Squid", 
            "Seaweed", 
            "Magnet", 
            "Worm", 
            "Minnow", 
            "Flakes", 
            "Insect", 
            "Maggot", 
            "Rapid Catcher"
        }, 
        FishContents = {
            "Sockeye Salmon", 
            "Trout", 
            "Carp", 
            "Minnow", 
            "Mackerel", 
            "Gudgeon", 
            "Cod", 
            "Haddock", 
            "White Bass", 
            "Sea Bass", 
            "Chub", 
            "Pumpkinseed"
        }, 
        CoinContents = {
            40, 
            120
        }, 
        From = "None"
    }, 
    ["Carbon Crate"] = {
        WeightPool = {
            160, 
            160
        }, 
        Chance = 2, 
        Rarity = "Rare", 
        Resilience = 50, 
        Description = "A large military grade crate, lost from some sort of commercial fishing boat. The date of it's disappearance is unknown. Therefore, finders keepers?- Opening it might give you an array of fish, bait, and money!", 
        Hint = "Fallen off of a commercial fishing boat.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        BuyMult = 3.5, 
        Price = 140, 
        XP = 50, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Carbon Crate!", 
            "A Crate!", 
            "Woah! A Crate!", 
            "A Carbon Crate!", 
            "Who left this here?", 
            "Where is this from??"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("crate"), 
        IsCrate = true, 
        CrateType = "FishOrCoins", 
        FishContents = {
            "Alligator Gar", 
            "Nurse Shark", 
            "Ribbon Eel", 
            "Eel", 
            "White Bass", 
            "Longtail Bass", 
            "Yellowfin Tuna", 
            "Bluefin Tuna", 
            "Squid", 
            "Lobster", 
            "Cod", 
            "Pike", 
            "Barracuda", 
            "Arapaima", 
            "Amberjack", 
            "Sturgeon", 
            "Longtail Bass", 
            "Squid", 
            "Mahi Mahi", 
            "Halibut", 
            "Coelacanth", 
            "Abyssacuda"
        }, 
        CoinContents = {
            130, 
            400
        }, 
        From = "None"
    }, 
    ["Fish Barrel"] = {
        WeightPool = {
            150, 
            150
        }, 
        Chance = 12, 
        Rarity = "Uncommon", 
        Resilience = 110, 
        Description = "A large wooden barrel with iron hoops. The barrel filled with a large array of ocean and freshwater fish that all seem pretty fresh. Therefore, finders keeps?- Opening it might give you an assortment of fish", 
        Hint = "Fallen off of a fishing boat.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 80, 
        XP = 40, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Fish Barrel!", 
            "Woah! A Fish Barrel!", 
            "A Fish Barrel!", 
            "Don't mind if I do!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("crate"), 
        From = "None", 
        IsCrate = true, 
        CrateType = "Fish", 
        FishContents = {
            "Sockeye Salmon", 
            "Trout", 
            "Bream", 
            "Sturgeon", 
            "Barracuda", 
            "Carp", 
            "Pufferfish", 
            "Bluefin Tuna", 
            "Yellowfin Tuna", 
            "Sockeye Salmon", 
            "Trout", 
            "Bream", 
            "Barracuda", 
            "Carp", 
            "Pike", 
            "Alligator Gar", 
            "Cod", 
            "Minnow", 
            "Longtail Bass", 
            "Mahi Mahi", 
            "Sardine", 
            "Crab", 
            "Amberjack", 
            "Arapaima", 
            "Perch", 
            "Sea Bass", 
            "Cod", 
            "Haddock", 
            "Sweetfish", 
            "Goldfish", 
            "Halibut", 
            "Minnow", 
            "Pale Tang", 
            "Porgy", 
            "Porgy", 
            "White Bass", 
            "Walleye", 
            "Redeye Bass", 
            "Sockeye Salmon", 
            "Trout", 
            "Bream", 
            "Sturgeon", 
            "Barracuda", 
            "Carp", 
            "Pufferfish", 
            "Bluefin Tuna", 
            "Yellowfin Tuna", 
            "Sockeye Salmon", 
            "Trout", 
            "Bream", 
            "Barracuda", 
            "Carp", 
            "Pike", 
            "Alligator Gar", 
            "Cod", 
            "Minnow", 
            "Longtail Bass", 
            "Mahi Mahi", 
            "Sardine", 
            "Crab", 
            "Amberjack", 
            "Arapaima", 
            "Perch", 
            "Sea Bass", 
            "Cod", 
            "Haddock", 
            "Sweetfish", 
            "Goldfish", 
            "Halibut", 
            "Minnow", 
            "Pale Tang", 
            "Porgy", 
            "Porgy", 
            "White Bass", 
            "Walleye", 
            "Redeye Bass", 
            "Golden Smallmouth Bass"
        }
    }, 
    ["Bait Crate"] = {
        WeightPool = {
            80, 
            80
        }, 
        Chance = 15, 
        Rarity = "Uncommon", 
        Resilience = 120, 
        Description = "A wooden crate with fabric over top to preserve the bait inside. Seemingly lost from a fishing boat of some kind. The bait is still alive and fresh. Therefore, finders keepers?- Opening it might give you an array of common and rare baits!", 
        Hint = "Fallen off of a fishing boat.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        BuyMult = 1.6, 
        Price = 75, 
        XP = 40, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Crate of Bait!", 
            "A Bait Crate!", 
            "Woah! A Crate!", 
            "A Crate!", 
            "Who left this here?", 
            "Oh, the shrimps still moving?", 
            "A Crate full of Bait!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("crate"), 
        From = "None", 
        IsCrate = true, 
        CrateType = "Bait", 
        BaitContents = {
            "Garbage", 
            "Garbage", 
            "Garbage", 
            "Shrimp", 
            "Seaweed", 
            "Bagel", 
            "Squid", 
            "Magnet", 
            "Worm", 
            "Minnow", 
            "Flakes", 
            "Insect", 
            "Fish Head", 
            "Rapid Catcher", 
            "instant Catcher", 
            "Super Flakes", 
            "Maggot"
        }
    }, 
    ["Quality Bait Crate"] = {
        WeightPool = {
            120, 
            120
        }, 
        Chance = 8, 
        Rarity = "Rare", 
        Resilience = 120, 
        Description = "A metal bait box with a rubber seal to protect the bait inside. Seemingly lost from a fishing boat of some kind. The bait is still alive and fresh. Therefore, finders keepers?- Opening it might give you an array of baits!", 
        Hint = "Fallen off of a fishing boat.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        BuyMult = 3.5, 
        Price = 150, 
        XP = 40, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Crate of Bait!", 
            "A Bait Crate!", 
            "Woah! A Crate!", 
            "A Crate!", 
            "Who left this here?", 
            "Oh, the shrimps still moving?", 
            "A Crate full of Bait!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("downward"), 
        From = "None", 
        IsCrate = true, 
        CrateType = "Bait", 
        BaitContents = {
            "Fish Head", 
            "Rapid Catcher", 
            "instant Catcher", 
            "Seaweed", 
            "Seaweed", 
            "Squid", 
            "Super Flakes", 
            "Maggot", 
            "Night Shrimp", 
            "Maggot", 
            "Maggot", 
            "Weird Algae", 
            "Shark Head"
        }
    }, 
    ["Enchant Relic"] = {
        WeightPool = {
            210, 
            210
        }, 
        Chance = 0.2, 
        Rarity = "Relic", 
        Resilience = 35, 
        ProgressEfficiency = 0.8, 
        Description = "A stone filled with the blessing of a Divine Lantern Keeper.. Returning it to it's throne under the Statue of Sovereignty will result in your currently equipped rod being engulfed in its power.", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 3500, 
        XP = 800, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I feel it's power..", 
            "Woah.. A Relic??", 
            "A Relic!!", 
            "I caught a Relic!", 
            "Please don't give me Wormhole.."
        }, 
        SparkleColor = Color3.fromRGB(126, 255, 216), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "None"
    }, 
    Bone = {
        WeightPool = {
            10, 
            25
        }, 
        Chance = 100 * v1["Brine Pool"].Trash, 
        Rarity = "Trash", 
        Resilience = 80, 
        Description = "A bone from the remains of a dissolved creature.", 
        Hint = "Find it in the Brine Pool.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 30, 
        XP = 25, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Oh.. a Bone!", 
            "A.. Bone?", 
            "How did I pull this up?", 
            "A Bone..?"
        }, 
        SparkleColor = Color3.fromRGB(255, 240, 162), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Brine Pool"
    }, 
    Gazerfish = {
        WeightPool = {
            80, 
            140
        }, 
        Chance = 100 * v1["Brine Pool"].Common, 
        Rarity = "Common", 
        Resilience = 85, 
        Description = "The Gazerfish is a fast-moving prey fish within the Brine Pool of the Desolate Deep. They have a singular large eyeball on the front of their bodies, which they can close to disguise themselves from possible predators during the night. When they are most active during the day, they swim near the surface looking for smaller creatures to feed on.", 
        Hint = "Found in the Brine Pool during the day.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 190, 
        XP = 100, 
        Seasons = {
            "Autumn", 
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Gazerfish!", 
            "Woah, a Gazerfish!", 
            "A Gazerfish!", 
            "I caught a Gazerfish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 158, 73), 
        HoldAnimation = l_fish_0:WaitForChild("underweight"), 
        From = "Brine Pool"
    }, 
    ["Brine Shrimp"] = {
        WeightPool = {
            1, 
            3
        }, 
        Chance = 90 * v1["Brine Pool"].Uncommon, 
        Rarity = "Uncommon", 
        Resilience = 65, 
        Description = "The Brine Shrimp is a small crustacean abundant in the Brine Pool within the Desolate Deep. They possess the ability to adapt and survive within harsh conditions, particularly incredibly salty water like the Brine Pool. They feed on microorganisms during the day, and are at the bottom of the food chain within the Brine Pool.", 
        Hint = "Found in the Brine Pool during the day.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 230, 
        XP = 130, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Brine Shrimp!", 
            "Woah, a Brine Shrimp!", 
            "A Brine Shrimp!", 
            "I caught a Brine Shrimp!", 
            "I caught a Brine Shrimp!", 
            "Shrimplo Dimplo!"
        }, 
        SparkleColor = Color3.fromRGB(85, 255, 133), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Brine Pool"
    }, 
    ["Globe Jellyfish"] = {
        WeightPool = {
            140, 
            240
        }, 
        Chance = 60 * v1["Brine Pool"].Unusual, 
        Rarity = "Unusual", 
        Resilience = 25, 
        Description = "The Globe Jellyfish is a distant relative of the elusive Emperor Jellyfish. They are highly venomous instead of electrifying, which makes it a threat to any unfortunate creatures who come in contact with it.", 
        Hint = "Found in the saline waters of the Brine Pool.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 300, 
        XP = 150, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Ouu a Globe Jellyfish!", 
            "Oh my Globe!", 
            "A Globe Jellyfish!"
        }, 
        SparkleColor = Color3.fromRGB(87, 232, 133), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Brine Pool"
    }, 
    ["Dweller Catfish"] = {
        WeightPool = {
            100, 
            160
        }, 
        Chance = 40 * v1["Brine Pool"].Rare, 
        Rarity = "Rare", 
        Resilience = 20, 
        ProgressEfficiency = 0.8, 
        Description = "The Dweller Catfish is found near the bottom of the Desolate Brine Pool. They have bright fins and dark scales throughout their whole body, which they use to camouflage from possible predators within the Brine Pool.", 
        Hint = "Found in the Brine Pool.", 
        FavouriteBait = "Weird Algae", 
        FavouriteTime = "Day", 
        Price = 440, 
        XP = 150, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Dweller Catfish!", 
            "Dweller Catfishhhh", 
            "A Dweller Catfish!", 
            "Dweller Catfish!"
        }, 
        SparkleColor = Color3.fromRGB(97, 255, 184), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Brine Pool"
    }, 
    Eyefestation = {
        WeightPool = {
            4800, 
            6500
        }, 
        Chance = 0.05, 
        Rarity = "Legendary", 
        Resilience = 15, 
        ProgressEfficiency = 0.7, 
        Description = "The Eyefestation is an evolved breed of Bull Sharks. They possess a large amount of bright green eyes all over their face for spotting prey in the Brine Pool to feed on. The Eyefestation inhibits aggressive behaviour towards other creatures, but this is likely a territorial response. If something happens to gaze into one of the Eyefestation's many eyes, they will be put in a dazed state where they become a vulnerable target.", 
        Hint = "Found in the Brine Pool.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 3000, 
        XP = 1000, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "WOAH! EYFESTATION??", 
            "Eyefestation!!", 
            "It's looking at me..", 
            "I feel dizzy!", 
            "Wait.. This looks familiar.."
        }, 
        SparkleColor = Color3.fromRGB(82, 255, 137), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        HideInBestiary = true
    }, 
    ["Brine Phantom"] = {
        WeightPool = {
            4800, 
            6500
        }, 
        Chance = 0.05, 
        Rarity = "Legendary", 
        Resilience = 15, 
        ProgressEfficiency = 0.7, 
        Description = "The Brine Phantom is a hostile predator of the Desolate Deep Brine Pool. They possess several sharp mandibles on the front of their face, which they use to subdue prey. The Brine Phantom inhibits aggressive behaviour towards other creatures that happen to come anywhere close to it.", 
        Hint = "Found in the Brine Pool.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 3000, 
        XP = 1000, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "WOAH! A BRINE PHANTOM??", 
            "BRINE PHANTOM!!", 
            "AHHHHHHH!!!!"
        }, 
        SparkleColor = Color3.fromRGB(82, 255, 137), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Brine Pool"
    }, 
    ["Spectral Serpent"] = {
        WeightPool = {
            110000, 
            130000
        }, 
        Chance = 0.02, 
        Rarity = "Mythical", 
        Resilience = 10, 
        ProgressEfficiency = 0.2, 
        Description = "The Spectral Serpent is an aggressive and ginormous sea serpent species located in the Brine Pool of the Desolate Deep. They possess a translucent exo-membrane covering the inside of their body, as well as 4 bioluminescent eyes. They tend to lurk deeper within the Brine Pool, where they feed on microorganisms. Despite their specific diet, they have many sharp teeth and mandibles along with their hammerhead-shaped skull, which they can use to easily fend off invasive threats. When hooked, they put up an intense fight for even the most experienced anglers.", 
        Hint = "???", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = "Night", 
        Price = 9000, 
        XP = 3500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A SPECTRAL SERPENT!!", 
            "IT'S HEAVY!", 
            "WHAT IS THIS THING?!", 
            "WOAH!!!", 
            "SS-S-S-SSSPEECTRAL SERPENT!!!!!"
        }, 
        SparkleColor = Color3.fromRGB(90, 255, 137), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Brine Pool"
    }, 
    Stalactite = {
        WeightPool = {
            60, 
            130
        }, 
        Chance = 100 * v1["Desolate Deep"].Trash, 
        Rarity = "Trash", 
        Resilience = 80, 
        Description = "A sharp and spiky rock formation that has fallen from the ceiling of a formidable cavern.", 
        Hint = "Find it fallen in the waters of the Desolate Deep.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 35, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Oh.. a Stalactite!", 
            "A.. Stalactite?", 
            "How did I pull this up?", 
            "A Stalactite..?", 
            "It poked me!", 
            "That was surprisingly heavy.."
        }, 
        SparkleColor = Color3.fromRGB(215, 210, 255), 
        HoldAnimation = l_fish_0:WaitForChild("underweight"), 
        From = "Desolate Deep"
    }, 
    ["Coral Geode"] = {
        WeightPool = {
            180, 
            180
        }, 
        Chance = 17 * v1["Desolate Deep"].Uncommon, 
        Rarity = "Uncommon", 
        Resilience = 120, 
        Description = "A geode filled with deep dark items and fish. Possibly has been untouched for years!- Like a coral reef Christmas!", 
        Hint = "Found in the Desolate Deep", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        BuyMult = 3, 
        Price = 200, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ooo, shiny!", 
            "A rock...?!", 
            "Woah! Glowy thing!", 
            "A Geode!", 
            "What's this thing?"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("crate"), 
        IsCrate = true, 
        CrateType = "All", 
        BaitContents = {
            "Coral", 
            "Coral", 
            "Coral", 
            "Coral", 
            "Coral", 
            "Maggot", 
            "Maggot", 
            "Minnow", 
            "Truffle Worm", 
            "Deep Coral", 
            "Deep Coral", 
            "Deep Coral", 
            "Night Shrimp", 
            "Rapid Catcher", 
            "instant Catcher", 
            "Super Flakes", 
            "Night Shrimp", 
            "Rapid Catcher", 
            "Super Flakes", 
            "Truffle Worm", 
            "Truffle Worm"
        }, 
        FishContents = {
            "Slate Tuna", 
            "Banditfish", 
            "Globe Jellyfish", 
            "Gazerfish", 
            "Phantom Ray", 
            "Stalactite", 
            "Stalactite", 
            "Cockatoo Squid", 
            "Banditfish", 
            "Brine Shrimp", 
            "Brine Shrimp"
        }, 
        CoinContents = {
            150, 
            500
        }, 
        From = "Desolate Deep"
    }, 
    ["Horseshoe Crab"] = {
        WeightPool = {
            40, 
            90
        }, 
        Chance = 90, 
        Rarity = "Common", 
        Resilience = 70, 
        Description = "The Rockstar Hermit Crab is an oddly shaped crab, with an external piece of shell that covers their whole body. Underneath the shell, you can find their legs and claws. Despite being a crab, horseshoe crabs are harmless and their claws are weak. Caught with crab cages in the Desolate Deep.", 
        Hint = "Caught in the Desolate Deep using a crab cage.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 25, 
        XP = 60, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Rain"
        }, 
        Quips = {
            "A Horseshoe Crab!", 
            "Woah! A Horseshoe Crab", 
            "That thing is scary..", 
            "Ouuu! A Horseshoe Crab!"
        }, 
        SparkleColor = Color3.fromRGB(126, 103, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Desolate Deep"
    }, 
    ["Slate Tuna"] = {
        WeightPool = {
            300, 
            600
        }, 
        Chance = 90 * v1["Desolate Deep"].Common, 
        Rarity = "Common", 
        Resilience = 35, 
        Description = "With their Stone Exocranium on the front of their body, the invasive Slate Tuna is able to hunt and kill pray at alarmingly high rates. However, this stone noggin of theirs also ends up in slower swim speeds for this predator, resulting with this fish being lower down on the food chain in this deep chasm.", 
        Hint = "Found commonly in the Desolate Deep.", 
        FavouriteBait = "Super Flakes", 
        FavouriteTime = nil, 
        Price = 70, 
        XP = 25, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Rain"
        }, 
        Quips = {
            "I caught a Slate Tuna!", 
            "Ouu! A Slate Tuna!", 
            "A Slate Tuna!", 
            "Slate Tuah!", 
            "Oh my slate!", 
            "Slate on that thang!"
        }, 
        SparkleColor = Color3.fromRGB(128, 113, 173), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Desolate Deep"
    }, 
    ["Phantom Ray"] = {
        WeightPool = {
            40, 
            60
        }, 
        Chance = 90 * v1["Desolate Deep"].Uncommon, 
        Rarity = "Uncommon", 
        Resilience = 45, 
        Description = "The Phantom Ray is a menacing yet beautiful species of ray, resembling the shape of an anchor with bioluminescent engravings throughout its body, as well as a translucent fin that they use to move around. They typically like to feed on microorganisms during the night, and spend most of the day sitting underneath ledges or large vegetation.", 
        Hint = "Found in the Desolate Deep.", 
        FavouriteBait = "Weird Algae", 
        FavouriteTime = "Night", 
        Price = 140, 
        XP = 60, 
        Seasons = {
            "Summer", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Phantom Ray!", 
            "Phantuah!", 
            "Ouu! A Phantom Ray!", 
            "It looks like an anchor!"
        }, 
        SparkleColor = Color3.fromRGB(152, 148, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "Desolate Deep"
    }, 
    ["Rockstar Hermit Crab"] = {
        WeightPool = {
            4, 
            12
        }, 
        Chance = 25 * v1["Desolate Deep"].Unusual, 
        Rarity = "Unusual", 
        Resilience = 100, 
        Description = "The Rockstar Hermit Crab is a unique evolutionary species, originating from the simple hermit crab. They possess antennae resembling two lightning-bolts on either side of their head, which is where their name comes from. Caught with rods or crab cages in the Desolate Deep.", 
        Hint = "Caught in the Desolate Deep using a crab cage.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 65, 
        XP = 75, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Rockstar Hermit Crab!", 
            "Woah! A Rockstar Hermit Crab", 
            "Hey now, you're a rockstar.", 
            "Ou! A Rockstar Hermit Crab!"
        }, 
        SparkleColor = Color3.fromRGB(126, 103, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Desolate Deep"
    }, 
    ["Cockatoo Squid"] = {
        WeightPool = {
            4, 
            20
        }, 
        Chance = 45 * v1["Desolate Deep"].Unusual, 
        Rarity = "Unusual", 
        Resilience = 35, 
        Description = "The Cockatoo Squid is an intriguing species of squid. Their bodies are almost entirely translucent and bioluminescent, which they can use to hide from possible predators. They typically leave their hiding spots at night in search of microorganisms to feed on.", 
        Hint = "Found in the Desolate Deep during the night.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Night", 
        Price = 200, 
        XP = 65, 
        Seasons = {
            "Summer", 
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Cockatoo Squid!", 
            "Ouu! A Cockatoo Squid!", 
            "So cool!"
        }, 
        SparkleColor = Color3.fromRGB(185, 186, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Desolate Deep"
    }, 
    Banditfish = {
        WeightPool = {
            150, 
            200
        }, 
        Chance = 75 * v1["Desolate Deep"].Rare, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "Banditfish are insanely fast hunters and swimmers, hence their name. They have a single rudder-like fin at the back of their bodies, which they move in a swaying motion to glide throughout the waters. Despite being remarkably good at hunting smaller prey, they are still no match for the greater creatures within the Desolate Deep.", 
        Hint = "Caught in the Desolate Deep", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 250, 
        XP = 100, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Bandit Fish!", 
            "It's a Bandit Fish!", 
            "Woahhh, A Bandit Fish", 
            "It pickpocketed me! >:("
        }, 
        SparkleColor = Color3.fromRGB(198, 157, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Desolate Deep"
    }, 
    ["Midnight Axolotl"] = {
        WeightPool = {
            10, 
            30
        }, 
        Chance = 0.15, 
        Rarity = "Legendary", 
        Resilience = 50, 
        ProgressEfficiency = 0.3, 
        Description = "The Midnight Axolotl is a variant of Axolotl that has adapted to the Desolate Deep. Midnight Axolotls are known for their adorable looks and giant size compared to regular Axolotls. They are most commonly seen at night while other fish sleep. It has been theorized that the glowing gills on the sides of their head have evolved, allowing them to use echolocation to see predators in even the darkest waters. Despite being on the lower end of the food chain, they use their agility and abilities to hide within the Desolate Deep. It is currently unknown how many Midnight Axolotls are residing there", 
        Hint = "Hangs out near the deepest parts of the Desolate Deep during the Night.", 
        FavouriteBait = "Insect", 
        FavouriteTime = "Night", 
        Price = 1100, 
        XP = 550, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "This an Axolotl..", 
            "Midnight Axolotl!", 
            "It's so cute!", 
            "That's a big axolotl!"
        }, 
        SparkleColor = Color3.fromRGB(255, 141, 42), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        ViewportSizeOffset = 2, 
        From = "Desolate Deep"
    }, 
    ["Barbed Shark"] = {
        WeightPool = {
            7000, 
            9500
        }, 
        Chance = 0.08, 
        Rarity = "Legendary", 
        Resilience = 10, 
        ProgressEfficiency = 0.4, 
        Description = "The Barbed Shark, a fierce apex predator within the Desolate Deep, is not a fish to be messed with. When they bite on to a hook, they put up a fierce fight, but give a great reward due to the valuable materials that make up their many scales.", 
        Hint = "Can be found within the Desolate Deep", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = nil, 
        Price = 8300, 
        XP = 4000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "FINALLY!", 
            "FINALLY! I CAUGHT A BARBED SHARK!!", 
            "ALKSJDAHASBDJH", 
            "holy barb", 
            "BUHBUHBUHBARBED SHARK?!", 
            "olm my BARB!!!", 
            "YES YES YES!! BARBED SHARK!", 
            "AHHHHHHHHHHHHHHHHHHH"
        }, 
        SparkleColor = Color3.fromRGB(114, 58, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Desolate Deep"
    }, 
    ["Emperor Jellyfish"] = {
        WeightPool = {
            5000, 
            8000
        }, 
        Chance = 0.03, 
        Rarity = "Mythical", 
        Resilience = 20, 
        ProgressEfficiency = 0.25, 
        Description = "The Emperor Jellyfish is a very unique and incredibly rare breed of jellyfish, only found in the gloomy waters of the Desolate Deep. They carry around a stalactite in which they use as an offense mechanism against their prey. They are extremely electrifying to the touch, which makes them a menacing catch for most anglers.", 
        Hint = "???", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 6000, 
        XP = 4500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "WOAH! AN EMPEROR JELLYFISH!!", 
            "NO WAY!!", 
            "I CAUGHT THE EMPEROR JELLYFISH!!", 
            "IT STINGS!"
        }, 
        SparkleColor = Color3.fromRGB(143, 139, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Desolate Deep"
    }, 
    ["Sea Mine"] = {
        WeightPool = {
            2000, 
            3250
        }, 
        Chance = 0.1, 
        Rarity = "Mythical", 
        Resilience = 200, 
        Description = "An inactive naval sea mine that has somehow made its way down here. Caught in crab cages in the Desolate Deep.", 
        Hint = "Caught with crab cages in the Desolate Deep.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 4000, 
        XP = 2000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Sea Mine?!", 
            "How did this get down here?", 
            "I hope it doesn't explode!", 
            "Why do I hear beeping..?"
        }, 
        SparkleColor = Color3.fromRGB(103, 103, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Desolate Deep"
    }, 
    ["Pale Tang"] = {
        WeightPool = {
            3, 
            15
        }, 
        Chance = 55, 
        Rarity = "Uncommon", 
        Resilience = 35, 
        Description = "The Pale Tang is a relatively common catch within Keepers Altar. Very similar to other Tangs such as the Red Tang, just pale!- No one is sure of the Pale Tangs origin, and how it got accustomed to the Keepers Altar.", 
        Hint = "Found in Keepers Altar.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = nil, 
        Price = 100, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Pale Tang!", 
            "Woah, a Pale Tang!", 
            "A Pale Tang!", 
            "I caught a Pale Tang!", 
            "I caught a Pale Tang!", 
            "Found her!.. But albino!"
        }, 
        SparkleColor = Color3.fromRGB(255, 187, 187), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Keepers Altar"
    }, 
    Bluefish = {
        WeightPool = {
            4, 
            9
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 34, 
        Description = "Bluefish are found inside Keepers Altar. They can inhabit some of the powerful keepers power that is present in Keepers Altars water. They are only awake during the day, as the power of the Altar is too much for them to handle during the night.", 
        Hint = "Swims quietly in Keepers Altar during the day.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 65, 
        XP = 75, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Woah, a Bluefish!", 
            "A Bluefish!", 
            "I caught a Bluefish!", 
            "Aw! I caught a Bluefish!"
        }, 
        SparkleColor = Color3.fromRGB(60, 63, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Keepers Altar"
    }, 
    Lapisjack = {
        WeightPool = {
            200, 
            400
        }, 
        Chance = 55, 
        Rarity = "Rare", 
        Resilience = 20, 
        Description = "The Lapisjack is a strong, fast-swimming fish known for their vigorous fights and robust body. Mostly active in spring, and only found in Keepers Altar. They are capable of sustaining their conscious when the Altar is active.", 
        Hint = "Found in Keepers Altar.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Day", 
        Price = 115, 
        XP = 80, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Rain"
        }, 
        Quips = {
            "A Lapisjack!", 
            "I caught an Lapisjack!", 
            "Woah, a Lapisjack!", 
            "Lumberjack- I mean Lapisjack!"
        }, 
        SparkleColor = Color3.fromRGB(219, 219, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Keepers Altar"
    }, 
    ["Keepers Guardian"] = {
        WeightPool = {
            200, 
            400
        }, 
        Chance = 15, 
        Rarity = "Rare", 
        Resilience = 25, 
        Description = "Whilst it is named the 'Keepers Guardian', they are actually friendly creatures! The Guardian can sense peoples intentions, and will only become violent when they notice someone with a harmful intention to it or the Keepers Altar.", 
        Hint = "Found in Keepers Altar.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 250, 
        XP = 120, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Keepers Guardian!", 
            "I caught a Keepers Guardian!", 
            "Woah, a Keepers Guardian!", 
            "What the?! A Keepers Guardian?!"
        }, 
        SparkleColor = Color3.fromRGB(56, 53, 134), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Keepers Altar"
    }, 
    ["Umbral Shark"] = {
        WeightPool = {
            1050, 
            1550
        }, 
        Chance = 0.01, 
        Rarity = "Legendary", 
        Resilience = 10, 
        ProgressEfficiency = 0.9, 
        Description = "Umbral Sharks are a nocturnal bottom feeder, spending most of their time on the floor or in small crevices. They are gentle and slow-moving until provoked. Once angered, they can be extremely strong swimmers and often will break fishing lines. They are extremely rare, as they don't often come high enough in the water for anyone to see.", 
        Hint = "Caught at night in Keepers Altar.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 1000, 
        XP = 500, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "An Umbral Shark!", 
            "Woah! An Umbral Shark!", 
            "I Caught an Umbral Shark!"
        }, 
        SparkleColor = Color3.fromRGB(151, 110, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Keepers Altar"
    }, 
    ["Red Snapper"] = {
        WeightPool = {
            10, 
            70
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 75, 
        Description = "The Red Snapper is a common salt water fish that can be commonly found all around Moosewoods oceans. They are a very noticeable fish with their obvious red and light red tones.", 
        Hint = "Found in saltwater near Moosewood Docks. Prefers the Summer and Autumn.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 70, 
        XP = 80, 
        Seasons = {
            "Summer", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Red Snapper!", 
            "Woah! I caught a Red Snapper!", 
            "I caught a Red Snapper!", 
            "Red Snapper!!!", 
            "Oh Snap!"
        }, 
        SparkleColor = Color3.fromRGB(255, 74, 74), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Moosewood"
    }, 
    Anchovy = {
        WeightPool = {
            1, 
            3
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 100, 
        Description = "Anchovies are extremely small and slender fish, with a silvery sheen. They are known for their schooling behaviour and are a common catch near Moosewood.", 
        Hint = "Caught in all saltwater\226\128\153s of Moosewood", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 30, 
        XP = 20, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I caught an Anchovy..", 
            "An Anchovy!", 
            "It really put up a battle!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    ["Largemouth Bass"] = {
        WeightPool = {
            10, 
            45
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Largemouth Bass is a common freshwater fish found in Moosewood known for its large mouth and aggressive feeding behaviour. It's found in various habitats, such as lakes, ponds, and rivers, where the water is warm and there's plenty of vegetation. Largemouth Bass are also known for their camouflage, with a greenish color on their backs that helps them blend in with their surroundings.", 
        Hint = "Found in Moosewoods freshwater. Seems to prefer worms and other small baits.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 85, 
        XP = 20, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Now, where's the snare?", 
            "Woah!", 
            "Awesome!", 
            "A Largemouth Bass!", 
            "Ou! A Bass!"
        }, 
        SparkleColor = Color3.fromRGB(172, 255, 134), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    Trout = {
        WeightPool = {
            9, 
            50
        }, 
        Chance = 85, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Trout is a common freshwater fish found in all waters of Moosewood & Roslit. Trouts are well recognized for their interesting dotted patterns and pinkish-red ribbon across the sides of their soft bodies. Trouts also interestingly have two hearts to help efficiently pump blood throughout their body.", 
        Hint = "Can be found in plenty of common waters in Moosewood & Roslit.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 65, 
        XP = 40, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I thought theres a rainbow?", 
            "Woah, a Trout!", 
            "Woah!", 
            "A Trout!", 
            "I caught a Trout!"
        }, 
        SparkleColor = Color3.fromRGB(99, 168, 94), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    Bream = {
        WeightPool = {
            11, 
            27
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "Breams are school fish with deep bodies, flat sides and a small head. The bream loves worms and is most commonly found in Moosewoods freshwater.", 
        Hint = "Found in freshwaters, and along ocean beaches. Prefers day.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 60, 
        XP = 30, 
        Seasons = {
            "Spring", 
            "Winter"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Bream!", 
            "Bream!", 
            "I caught a Bream!", 
            "Woah, a Bream!", 
            "Hello, Bream!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 193), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    ["Sockeye Salmon"] = {
        WeightPool = {
            20, 
            70
        }, 
        Chance = 90, 
        Rarity = "Common", 
        Resilience = 90, 
        ProgressEfficiency = 1.2, 
        Description = "The Sockeye Salmon are a very common type of salmon found near Moosewood, known for their vibrant red and green colours and interesting habits when laying eggs. They are very common during colder seasons such as Autumn, as that is the time most Sockeye Salmon lay their eggs.", 
        Hint = "Resides in oceans, some freshwaters along Moosewood. Prefers shrimp.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = nil, 
        Price = 45, 
        XP = 25, 
        Seasons = {
            "Autumn", 
            "Winter"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Salmoff!", 
            "Woah!", 
            "Awesome!", 
            "A Sockeye Salmon!", 
            "Woah, A Sockeye Salmon!", 
            "A Salmon!"
        }, 
        SparkleColor = Color3.fromRGB(255, 160, 160), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Moosewood"
    }, 
    Carp = {
        WeightPool = {
            10, 
            50
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "Carps are freshwater fish that are known for their whisker-like barbels around their mouth. Carps can adapt to plenty of different environments, as they can thrive in various water conditions. Due to their resilience, they are a common choice for stocking man-made ponds and lakes! They are also pretty cute, in my opinion.", 
        Hint = "Found in the back of Moosewood Pond.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = nil, 
        Price = 110, 
        XP = 80, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Is it magic?", 
            "Woah, a Carp!", 
            "It's a Carp!", 
            "Woahh! This is bigger than I thought.", 
            "Carp-tastic!", 
            "!!!", 
            "Woah!", 
            "A Carp! My skill are sharp!"
        }, 
        SparkleColor = Color3.fromRGB(255, 186, 125), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Moosewood"
    }, 
    ["Yellowfin Tuna"] = {
        WeightPool = {
            450, 
            1360
        }, 
        Chance = 65, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "The Yellowfin Tuna is a species of tuna known for their speed and agility. The Yellowfin Tuna can be found best near Moosewoods waters, but you can find them in most open saltwater due to them being highly migratory. They are less endangered than Bluefin Tuna but still face threats.", 
        Hint = "Found in open saltwater near moosewood.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 120, 
        XP = 80, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Yellowfin Tuna!", 
            "I caught a Yellowfin Tuna!", 
            "Woah, a Yellowfin Tuna!", 
            "Tunaaaaa!", 
            "What's up, Tuna!"
        }, 
        SparkleColor = Color3.fromRGB(255, 235, 135), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Moosewood"
    }, 
    Goldfish = {
        WeightPool = {
            2, 
            7
        }, 
        Chance = 55, 
        Rarity = "Uncommon", 
        Resilience = 90, 
        Description = "Goldfish are found in Moosewoods pond and are best awake during the nice summer days. Even though they look weak, goldfish are highly tolerant of turbid waters, temperature fluctuations, and low levels of dissolved oxygen.", 
        Hint = "Lives in calm ponds. Very easy to catch with bagels.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 65, 
        XP = 75, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Doesn't look very gold..", 
            "Woah, a Goldfish!", 
            "A goldfish!", 
            "I caught a Goldfish!", 
            "Aw! I caught a Goldfish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 184, 69), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    Snook = {
        WeightPool = {
            30, 
            70
        }, 
        Chance = 45, 
        Rarity = "Unusual", 
        Resilience = 85, 
        Description = "The Common Snook is a cute salt water swimmer found commonly near Moosewood Docks. They are easy noticeable due to their thin black stripe across their body, and easily catchable due to schools during spawning season in spring.", 
        Hint = "Can be found close to ocean docks of Moosewood.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = nil, 
        Price = 110, 
        XP = 45, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "I caught a Snook!", 
            "It's a Snook!", 
            "A Snook!", 
            "Look at this Snook!"
        }, 
        SparkleColor = Color3.fromRGB(255, 233, 125), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Moosewood"
    }, 
    Flounder = {
        WeightPool = {
            15, 
            55
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 80, 
        Description = "Flounders are a demersal flatfish- meaning they feed at the bottom of the ocean, and has a flat body to blend in with the seafloor. Both of a flounders eyes are on one side, pointing upwards to the sky. They are easy to find in dark areas with a lot of surface or at night near Moosewood Docks.", 
        Hint = "Lays flat at the bottom of the ocean. Prefers the night.", 
        FavouriteBait = "Squid", 
        FavouriteTime = "Night", 
        Price = 120, 
        XP = 80, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "A Flounder!", 
            "A Flatfish!", 
            "I caught a Flounder!"
        }, 
        SparkleColor = Color3.fromRGB(86, 68, 57), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    Eel = {
        WeightPool = {
            8, 
            45
        }, 
        Chance = 30, 
        Rarity = "Unusual", 
        Resilience = 65, 
        Description = "Eels are a long snake-like, ray-finned fish that is primarily nocturnal. They have a keen sense of smell and can be harmful to humans due to their strong jaws with sharp teeth. Some eels also contain toxins that will destroy red blood cells. Eels move in an interesting way due to them not having pelvic or pectoral fins. To swim, eels generate waves that travel the length of their body, animating them similar to snakes.", 
        Hint = "Only comes out at night. Can be found in all kinds of habitats near Moosewood.", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 130, 
        XP = 90, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Is it a snake?", 
            "An Eel!", 
            "I think some slime got on me.", 
            "Woah! An Eel!", 
            "H-eel-lo!", 
            "An Eel! Things just got REAL!"
        }, 
        SparkleColor = Color3.fromRGB(255, 233, 226), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    Pike = {
        WeightPool = {
            12, 
            35
        }, 
        Chance = 45, 
        Rarity = "Unusual", 
        Resilience = 55, 
        Description = "Pikes are a freshwater predator known for its elongated body, sharp teeth, and aggressive hunting behaviour. It's a voracious carnivore that preys on smaller fish, frogs, and even small mammals near the water's edge. Pikes have a unique ability to ambush their prey by remaining almost motionless in the water, then striking with incredible speed to catch their meal.", 
        Hint = "Found in Moosewoods freshwater. Seems to prefer insect baits. Very vicious.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 230, 
        XP = 90, 
        Seasons = {
            "Autumn", 
            "Spring"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Pike!", 
            "I caught a Pike!", 
            "Woah! a Pike!", 
            "PIKE!!!", 
            "I'd prefer a lance.", 
            "A Pike?!", 
            "That's a big Pike!"
        }, 
        SparkleColor = Color3.fromRGB(93, 140, 109), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Moosewood"
    }, 
    ["Whiptail Catfish"] = {
        WeightPool = {
            10, 
            30
        }, 
        Chance = 0.05, 
        Rarity = "Legendary", 
        Resilience = 40, 
        Description = "The Whiptail Catfish is a small herbivorous fish that have a long body which resembles a whiptail. They tend to be shy and often hide under plants and rocks during the day, but are most active at night.", 
        Hint = "Caught in Moosewood Pond during the night.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Night", 
        Price = 600, 
        XP = 200, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A CATFISH!", 
            "A Whiptail Catfish!", 
            "Watch me Whip!", 
            "Watch me Nae Nae!", 
            "Holy Whip-a-moly!"
        }, 
        SparkleColor = Color3.fromRGB(255, 175, 117), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Moosewood"
    }, 
    ["Whisker Bill"] = {
        WeightPool = {
            350, 
            1000
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 25, 
        ProgressEfficiency = 0.8, 
        Description = "The Whisker Bill is a mythical creature that was a popular staple of Moosewood Island before they were thought to be extinct. Whisker Bills are extremely strong, however are awkward swimmers due to their peculiar archetype.", 
        Hint = "???", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = nil, 
        Price = 3100, 
        XP = 150, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "The mythical Whisker Bill..", 
            "Woah.. A Whisker Bill..", 
            "I caught.. A Whisker Bill..", 
            "Woah...", 
            "I thought they were extinct!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Moosewood"
    }, 
    ["Fungal Cluster"] = {
        WeightPool = {
            9, 
            9
        }, 
        Chance = 22, 
        Rarity = "Trash", 
        Resilience = 120, 
        Description = "Offspring of the Giant Fungal Trees of Mushgrove Swamp. These mushrooms produce heavy spores which pollute the surrounding area and sky giving everything an uncomfortable and green feel.", 
        Hint = "Find it in Mushgrove Swamp. Gives off spores.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 9, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "Hmm..?"
        }, 
        SparkleColor = Color3.fromRGB(255, 0, 0), 
        HoldAnimation = l_fish_0:WaitForChild("underweight"), 
        From = "Mushgrove"
    }, 
    ["White Perch"] = {
        WeightPool = {
            2, 
            12
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 70, 
        Description = "The Perch is a common freshwater fish that is best found in Mushgrove Swamp Unlike the classic Perch, the White Perch has no noticeable stripes.", 
        Hint = "Found in Mushgrove.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 80, 
        XP = 80, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A White Perch!", 
            "I caught a White Perch!", 
            "Woah, a White Perch!", 
            "Aww! A White Perch!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Mushgrove"
    }, 
    ["Swamp Bass"] = {
        WeightPool = {
            20, 
            60
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Swamp Bass is species of Bass that can only be found in Swamp water. They are extremely similar to Smallmouth Bass besides their special adaptation They have chameleon-like camouflage. This allows them to nearly entirely avoid being a prey of larger fish and Alligators.", 
        Hint = "Can be found in Mushgrove Swamp.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 60, 
        XP = 50, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "A Swamp Bass!", 
            "I caught a Swamp Bass!", 
            "Woah! A Swamp Bass!", 
            "Ouu! A Swamp Bass!"
        }, 
        SparkleColor = Color3.fromRGB(137, 255, 116), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Mushgrove"
    }, 
    Bowfin = {
        WeightPool = {
            30, 
            60
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "The Mudfish, also known as Bowfin, is a resilient, ancient fish species known for its ability to survive in harsh, low-oxygen environments like swamps and muddy waters. They can be found all over Mushgrove Swamp, especially lurking in dense vegetation and during the night.", 
        Hint = "Caught in Mushgrove Swamp at night.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Night", 
        Price = 100, 
        XP = 50, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Mudfish!", 
            "Ouu, A Mudfish!", 
            "I caught a Mudfish!"
        }, 
        SparkleColor = Color3.fromRGB(189, 125, 95), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Mushgrove"
    }, 
    ["Grey Carp"] = {
        WeightPool = {
            20, 
            70
        }, 
        Chance = 55, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "The Grey Carp is a sturdy freshwater fish known for its strength and adaptability. They can be found in Mushgrove Swamp feeding on plants and small insects. The Grey Carp is extremely strong, and is a tough battle to catch.", 
        Hint = "Found in Mushgrove Swamp near the fallen watch tower.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = nil, 
        Price = 120, 
        XP = 75, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Autumn"
        }, 
        Quips = {
            "Is it grey magic?", 
            "Woah, a Grey Carp!", 
            "It's a Carp!", 
            "Woahh! A Grey Carp!!", 
            "Carp-tastic!", 
            "!!!", 
            "Woah! Grey Carp!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Mushgrove"
    }, 
    ["Swamp Scallop"] = {
        WeightPool = {
            6, 
            14
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 90, 
        Description = "Swamp Scallops are a special kind of Scallops with a rich umami taste. They formed from an invasive growth of the Scallop population in Mushgrove Swamp.", 
        Hint = "Can be caught while cage fishing in mushgrove.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 150, 
        XP = 40, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Swamp Scallop!", 
            "Woah! A Swamp Scallop", 
            "Awesome!", 
            "A Swamp Scallop!", 
            "Ou! A Swamp Scallop!"
        }, 
        SparkleColor = Color3.fromRGB(142, 185, 78), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Mushgrove"
    }, 
    ["Mushgrove Crab"] = {
        WeightPool = {
            6, 
            14
        }, 
        Chance = 14, 
        Rarity = "Rare", 
        Resilience = 90, 
        Description = "The Mushgrove Crab is a rare species of crab. They have fully adapted to the Mushgrove Swamp and commonly eat off of the massive fungal life that has over taken the swamp.", 
        Hint = "Can be caught while cage fishing in mushgrove.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 330, 
        XP = 80, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Crusty Mushgrove Crab!", 
            "Woah! A Mushgrove Crab", 
            "Awesome!", 
            "A Mushgrove Crab!", 
            "Ou! A Mushgrove Crab!"
        }, 
        SparkleColor = Color3.fromRGB(185, 56, 52), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Mushgrove"
    }, 
    ["Marsh Gar"] = {
        WeightPool = {
            170, 
            380
        }, 
        Chance = 30, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "The Marsh Gar is a large vicious marsh water fish that can be found in Mushgrove Swamp. March Gar are extremely strong hunters, using their whiskers to sense prey in foggy waters.", 
        Hint = "Found under the bridges of Mushgrove Swamp.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = nil, 
        Price = 280, 
        XP = 100, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Gar!", 
            "I caught a Marsh Gar!", 
            "Woah! A Marsh Gar!", 
            "Oh my Gar!"
        }, 
        SparkleColor = Color3.fromRGB(180, 36, 36), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Mushgrove"
    }, 
    Catfish = {
        WeightPool = {
            50, 
            150
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "The Catfish is a large, whiskered bottom-dweller with a sturdy build and smooth, scale-less skin. Known for its whisker-like barbels, which help it sense food in murky waters of Mushgrove Swamp, the catfish is a resilient and adaptable fish.", 
        Hint = "Can be found in Mushgrove Swamp during the night.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Night", 
        Price = 300, 
        XP = 120, 
        Seasons = {
            "Autumn", 
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Catfish!", 
            "Meowwww!", 
            "Where is Dogfish?", 
            "Kitty Cat Meow Meow", 
            "I caught a Catfish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Mushgrove"
    }, 
    Alligator = {
        WeightPool = {
            1500, 
            3000
        }, 
        Chance = 0.9, 
        Rarity = "Legendary", 
        Resilience = 15, 
        ProgressEfficiency = 0.8, 
        Description = "The Alligator is a massive, fearsome reptile known for its powerful bite and armoured body. Found in Mushgrove Swamp, Alligators are the apex predator with a stealthy and ambush-based hunting style.", 
        Hint = "Found in Mushgrove Swamp during the night.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 700, 
        XP = 400, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Foggy, Rain"
        }, 
        Quips = {
            "WOAH!!", 
            "OH MY GOD!!", 
            "AN ALLIGATOR!", 
            "WHAT????"
        }, 
        SparkleColor = Color3.fromRGB(153, 255, 116), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "Mushgrove"
    }, 
    Handfish = {
        WeightPool = {
            20, 
            60
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 50, 
        ProgressEfficiency = 0.5, 
        Description = "The Handfish is a unique, small, and critically rare species with pectoral fins that resemble hands, which it uses to 'walk' along the ocean floor rather than swim. They can only be found stomping on the floors of Mushgrove Swamp", 
        Hint = "Can be found in Mushgrove Swamp.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 1000, 
        XP = 500, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Handfish!", 
            "They look like mine!", 
            "Woah! A Handfish", 
            "Hey. Don't get handsy with me!", 
            "Kinda weird lookin'..."
        }, 
        SparkleColor = Color3.fromRGB(255, 234, 181), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Mushgrove"
    }, 
    ["Sea Bass"] = {
        WeightPool = {
            20, 
            60
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Sea Bass is a popular catch for many anglers, known for its elongated body and aggressive fighting behaviour when hooked. They can be found all over the world in all sorts of salt waters.", 
        Hint = "In salt waters.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 95, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Sea Bass!", 
            "I caught a Sea Bass!", 
            "Woah! A Sea Bass!", 
            "Ouu! A Bass!"
        }, 
        SparkleColor = Color3.fromRGB(203, 203, 203), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Porgy = {
        WeightPool = {
            5, 
            30
        }, 
        Chance = 60, 
        Rarity = "Common", 
        Resilience = 65, 
        Description = "Porgies are a common catch for coastal anglers. They are a relatively easy to catch ocean fish with no real special qualities besides their taste and fun to say name.", 
        Hint = "Found all over the Ocean during the day and prefers shrimp.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Day", 
        Price = 90, 
        XP = 40, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "A Corgi.. I mean Porgy??", 
            "Woah, a Porgy!", 
            "Nice, A Porgy!", 
            "A Porgy!", 
            "I caught a Porgy!"
        }, 
        SparkleColor = Color3.fromRGB(248, 255, 169), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Mullet = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 65, 
        Description = "The Mullet is a streamlined, silver-scaled fish known for its schooling behaviour and preference for shallow coastal and freshwater environments. Mullets are agile swimmers with a forked tail and a tough, sturdy body, making them a popular catch for beginners and seasoned anglers alike.", 
        Hint = "Found all over the Ocean, prefers bagels.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = nil, 
        Price = 90, 
        XP = 40, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "The hairstyle??", 
            "Woah, a Mullet!", 
            "Nice, A Mullet!", 
            "A Mullet!", 
            "I caught an Outdated Hairstyle!"
        }, 
        SparkleColor = Color3.fromRGB(183, 249, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Sardine = {
        WeightPool = {
            1, 
            3
        }, 
        Chance = 90, 
        Rarity = "Common", 
        Resilience = 90, 
        Description = "Sardines are small schooling fish, known for their high oil content, silver scales, and long tiny bodies.", 
        Hint = "Found commonly in the open ocean.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 30, 
        XP = 20, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I caught a Sardine!", 
            "Ouu! A Sardine!", 
            "A Sardine!"
        }, 
        SparkleColor = Color3.fromRGB(185, 185, 185), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Mackerel = {
        WeightPool = {
            10, 
            40
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 85, 
        Description = "The Mackerel is a fast-swimming, silver fish with distinctive stripes and high-oil content. Mackerel are most active from spring to autumn in mildly warm weather.", 
        Hint = "Found in mildly warm saltwater.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Day", 
        Price = 75, 
        XP = 80, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Mackerel!", 
            "I caught a Mackerel!", 
            "Woah, a Mackerel!", 
            "Mackerelllll!", 
            "What's up, Mackerel!", 
            "Holy Mackerel!"
        }, 
        SparkleColor = Color3.fromRGB(207, 207, 207), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Haddock = {
        WeightPool = {
            15, 
            40
        }, 
        Chance = 110, 
        Rarity = "Common", 
        Resilience = 85, 
        Description = "Haddock are small, silvery fish found in cold ocean waters. Haddock are often found in large schools, they are relatively easy to catch and are easy to find near their signature 'Haddock Rock'.", 
        Hint = "Found in schools near 'Haddock rock'.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 50, 
        XP = 60, 
        Seasons = {
            "Autumn", 
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Haddock!", 
            "Woah, a Haddock!!"
        }, 
        SparkleColor = Color3.fromRGB(227, 227, 227), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Shrimp = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 45, 
        Rarity = "Common", 
        Resilience = 200, 
        Description = "Shrimp are small, versatile crustaceans that are most active from spring to autumn, and can be found in an abundance in deep oceans. Shrimp are predominantly nocturnal, making night fishing the most effective time.", 
        Hint = "Caught at night in deep oceans in crab cages.", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 45, 
        XP = 35, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Shrimp!", 
            "Woah! A Shrimp", 
            "Awesome!", 
            "A Shrimp!", 
            "Ou! A Shrimpy!"
        }, 
        SparkleColor = Color3.fromRGB(255, 107, 96), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    ["Sand Dollar"] = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 55, 
        Rarity = "Common", 
        Resilience = 200, 
        Description = "Sand dollars are species of flat, burrowing sea urchins.. Yeah, they are urchins! Fun fact The rattling of a fossilized Sand Dollar is their teeth-like sections moving around inside of them.", 
        Hint = "Can be easily caught while cage fishing. Best caught near docks and beaches.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 20, 
        XP = 35, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Sand Dollar!", 
            "Woah! A Sand Dollar", 
            "Awesome!", 
            "A Sand Dollar!", 
            "Ou! A Sand Dollar!"
        }, 
        SparkleColor = Color3.fromRGB(255, 227, 143), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Mussel = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 55, 
        Rarity = "Common", 
        Resilience = 200, 
        Description = "Mussels are small mollusc that can be easily found on rocks, near beaches, and near docks. They actually have one food and have very limited movement, so most mussels stay in one place their entire lives.. that's boring!", 
        Hint = "Can be easily caught while cage fishing. Best caught near docks and beaches.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 20, 
        XP = 35, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Mussel!", 
            "Woah! A Mussel", 
            "Awesome!", 
            "A Mussel!", 
            "Ou! A Mussel!"
        }, 
        SparkleColor = Color3.fromRGB(53, 53, 89), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Barracuda = {
        WeightPool = {
            55, 
            110
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 55, 
        Description = "Barracudas are large predatory fish, known for their fearsome appearance and ferocious behaviour. The barracuda is an adept saltwater hunter and are commonly mistaken as a hazard towards humans, when in reality they are relatively comfortable and friendly swimmers. They can be found in deep oceans, and near Moosewood.", 
        Hint = "Found in deeper saltwater and near Moosewood.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Day", 
        Price = 150, 
        XP = 90, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, a Barracuda!", 
            "I caught a Barracuda!", 
            "A Barracuda!!", 
            "!!!!"
        }, 
        SparkleColor = Color3.fromRGB(117, 141, 121), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Cod = {
        WeightPool = {
            20, 
            100
        }, 
        Chance = 75, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "Cod are robust, deep-water fish. Best found in the open cold oceans during winter and spring. Cods are a reliable and rewarding catch with substantial size and strong fighting ability.", 
        Hint = "Found in cold deep ocean water.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 90, 
        XP = 70, 
        Seasons = {
            "Winter", 
            "Spring"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Cod!", 
            "I caught a Cod!", 
            "Woah, a Cod!", 
            "Cod of duty!", 
            "What's up, Coddy!"
        }, 
        SparkleColor = Color3.fromRGB(207, 158, 139), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Salmon = {
        WeightPool = {
            40, 
            100
        }, 
        Chance = 70, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "Salmon are visually known for their silver skin and streamlined bodies. They are extremely strong swimmers and leapers, making them a difficult catch. You can find these Ocean Salmon in any deep bodies of salt water, and some freshwaters.", 
        Hint = "Found in oceans and some freshwaters.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 130, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Winter"
        }, 
        Weather = {
            "Rain", 
            "Clear"
        }, 
        Quips = {
            "Salmoff!", 
            "Woah!", 
            "Awesome!", 
            "A Salmon!", 
            "Woah, A Salmon!", 
            "A Salmon!!!"
        }, 
        SparkleColor = Color3.fromRGB(65, 166, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Amberjack = {
        WeightPool = {
            200, 
            400
        }, 
        Chance = 75, 
        Rarity = "Uncommon", 
        Resilience = 40, 
        Description = "The Amberjack is a strong, fast-swimming fish known for their vigorous fights and robust body. Mostly active in spring, and best caught in open ocean waters with live baitfish such as small minnows. The Amberjack is not rare or hard to come by, but it does put up an impressive battle when trying to catch.", 
        Hint = "Found in open saltwater.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Day", 
        Price = 115, 
        XP = 80, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Rain"
        }, 
        Quips = {
            "An Amberjack!", 
            "I caught an Amberjack!", 
            "Woah, an Amberjack!", 
            "Lumberjack- I mean Amberjack!"
        }, 
        SparkleColor = Color3.fromRGB(219, 219, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Crab = {
        WeightPool = {
            6, 
            14
        }, 
        Chance = 40, 
        Rarity = "Uncommon", 
        Resilience = 90, 
        Description = "Crabs are cute crustaceans that search the ocean floor for food. They can be found in plenty of ocean regions. Be careful, some can have harshly strong claws.", 
        Hint = "Can be caught while cage fishing in open oceans.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 100, 
        XP = 50, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Crusty Crab!", 
            "Woah! A Crab", 
            "Awesome!", 
            "A Crab!", 
            "Ou! A Crab!"
        }, 
        SparkleColor = Color3.fromRGB(209, 90, 90), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Scallop = {
        WeightPool = {
            2, 
            5
        }, 
        Chance = 40, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "Scallops are known for their ability to 'swim' by rapidly opening and closing their shells, which propels them through the water. They can be found best in sandy or grass filled areas of the ocean.", 
        Hint = "Best caught in sandy or grass filled areas of the ocean.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 100, 
        XP = 40, 
        Seasons = {
            "Winter", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Scallop!", 
            "Woah! A Scallop", 
            "Awesome!", 
            "A Scallop!", 
            "Ou! A Scallop!"
        }, 
        SparkleColor = Color3.fromRGB(255, 195, 135), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Prawn = {
        WeightPool = {
            1, 
            5
        }, 
        Chance = 40, 
        Rarity = "Uncommon", 
        Resilience = 200, 
        Description = "Prawns are prized crustaceans known for their delicate flavour and versatility. they are most active in summer, and can be found in an abundance in deep oceans. Prawns similar to shrimp-- are predominantly nocturnal, making night fishing the most effective time.", 
        Hint = "Caught at night in deep oceans in crab cages.", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 45, 
        XP = 35, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Prawn!", 
            "Woah! A Prawn", 
            "Awesome!", 
            "A Prawn!", 
            "Ou! A Prawn!"
        }, 
        SparkleColor = Color3.fromRGB(165, 255, 248), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Oyster = {
        WeightPool = {
            2, 
            5
        }, 
        Chance = 50, 
        Rarity = "Uncommon", 
        Resilience = 95, 
        Description = "Oysters are bivalve molluscs with rough, irregularly shaped shells. They are typically found in clusters, attached to submerged rocks and roots. They can be found all over Terapin Islands The Oysters help filter the water of Terrapin, leaving making it nearly a freshwater island.", 
        Hint = "Can be easily caught while cage fishing. Best caught near large rocks and all over Terrapin Island.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 30, 
        XP = 35, 
        Seasons = {
            "Summer", 
            "autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "An Oyster!", 
            "Woah! An Oyster", 
            "Awesome!", 
            "An Oyster!", 
            "Ou! An Oyster!"
        }, 
        SparkleColor = Color3.fromRGB(217, 194, 168), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    ["Nurse Shark"] = {
        WeightPool = {
            1000, 
            1500
        }, 
        Chance = 35, 
        Rarity = "Unusual", 
        Resilience = 35, 
        Description = "Nurse Sharks are a nocturnal bottom feeder, spending most of their time on the ocean floor or in small crevices. Despite their appearance, they are gentle and slow-moving. Nurse Sharks can 'suction feed', using their powerful jaws to scrape algae off surfaces.", 
        Hint = "Caught at night in the ocean.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Night", 
        Price = 200, 
        XP = 100, 
        Seasons = {
            "Summer", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Nurse Shark!", 
            "Woah! A Nurse Shark!", 
            "I Caught a Nurse Shark!"
        }, 
        SparkleColor = Color3.fromRGB(255, 152, 152), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Lobster = {
        WeightPool = {
            9, 
            28
        }, 
        Chance = 30, 
        Rarity = "Unusual", 
        Resilience = 200, 
        Description = "Lobsters are valuable crustaceans known for their rich, succulent meat. Lobsters are most active in the summer to autumn, and are commonly caught in crab cages during calm clear days.", 
        Hint = "Caught in oceans using a crab cage.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 130, 
        XP = 60, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Larry Lobster!", 
            "Woah! A Lobster", 
            "Awesome!", 
            "A Lobster!", 
            "Ou! A Lobster!"
        }, 
        SparkleColor = Color3.fromRGB(255, 57, 57), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Coelacanth = {
        WeightPool = {
            70, 
            100
        }, 
        Chance = 14, 
        Rarity = "Rare", 
        Resilience = 40, 
        Description = "The Coelacanth is an ancient fish with a distinctive shape and strong swimming behaviours Known as a 'living fossil,' this fish was thought to be extinct until its rediscovery in 1938. Coelacanths are deep-sea dwellers, often found in underwater caves and steep slopes.", 
        Hint = "Found in the Deep Ocean.", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 370, 
        XP = 300, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Woah, a Coelacanth!", 
            "I caught a Coelacanth!", 
            "It's a Coelacanth!", 
            "Nice! It's a Coelacanth!"
        }, 
        SparkleColor = Color3.fromRGB(76, 76, 76), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    ["Bluefin Tuna"] = {
        WeightPool = {
            1000, 
            2200
        }, 
        Chance = 35, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "The Bluefin Tuna is a very large and strong species of Tuna. They are highly migratory and can travel extremely long distances. Their population is critically low due to overfishing Making them rarer than other Tuna.", 
        Hint = "Found in deep open.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 350, 
        XP = 120, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Bluefin Tuna!", 
            "I caught a Bluefin Tuna!", 
            "Woah, a Bluefin Tuna!", 
            "Tunaaaaa!", 
            "What's up, Tuna!"
        }, 
        SparkleColor = Color3.fromRGB(125, 210, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean"
    }, 
    Halibut = {
        WeightPool = {
            1000, 
            2000
        }, 
        Chance = 40, 
        Rarity = "Rare", 
        Resilience = 40, 
        Description = "The Halibut is a large flatfish known for their impressive size and strength. They commonly feed on Haddock and can be found hunting near 'Haddock Rock' and in deep waters. ", 
        Hint = "Found on the floor ocean. Best found near Haddock.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 250, 
        XP = 100, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Halibut!", 
            "A Flatfish!", 
            "I Caught a Halibut!", 
            "Ou! A Halibut!"
        }, 
        SparkleColor = Color3.fromRGB(207, 129, 93), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Stingray = {
        WeightPool = {
            150, 
            300
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 50, 
        Description = "Graceful and flat, stingrays glide effortlessly through the water, using their wide pectoral fins to move. Their long, whip-like tails end in a sharp stinger, which they can use for defence. Stingrays are bottom dwellers, often found in rocky and sandy seafloors and caves.", 
        Hint = "Found in sea caves during the day.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 230, 
        XP = 100, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I caught a Stingray!", 
            "Woah.. a Stingray!", 
            "It stung me! Yeeowch!"
        }, 
        SparkleColor = Color3.fromRGB(180, 87, 50), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    ["Sea Urchin"] = {
        WeightPool = {
            2, 
            9
        }, 
        Chance = 15, 
        Rarity = "Rare", 
        Resilience = 200, 
        Description = "Sea Urchins are spiny, globular animals. Their hard shells are round and spiny. They use their spikes along with their tube feet to push themselves along the ocean terrain. Sea Urchins can be caught in any climate and traditionally only prefer sea water.", 
        Hint = "Can be rarely caught while cage fishing, especially in the ocean.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 320, 
        XP = 80, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Sea Urchin!", 
            "I caught a Sea Urchin!", 
            "Woah, an Urchin!"
        }, 
        SparkleColor = Color3.fromRGB(34, 32, 42), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    Anglerfish = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 12, 
        Rarity = "Rare", 
        Resilience = 35, 
        Description = "The anglerfish is a deep-sea predator known for it's bioluminescent lure that dangles in front of its mouth to attract prey. With its menacing appearance, sharp teeth, and eerie glow, the Anglerfish thrives in dark, deep waters, making it a rare and exciting catch in the Deep Ocean.", 
        Hint = "Found in the far, deep ocean during the night.", 
        FavouriteBait = "Squid", 
        FavouriteTime = "Night", 
        Price = 230, 
        XP = 100, 
        Seasons = {
            "Winter", 
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Woah, an Anglerfish!", 
            "No way! An anglerfish!", 
            "I caught an Anglerfish!"
        }, 
        SparkleColor = Color3.fromRGB(182, 25, 25), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ocean"
    }, 
    Pufferfish = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 12, 
        Rarity = "Rare", 
        Resilience = 65, 
        Description = "Pufferfish are clumsy swimmers that can fill their elastic stomachs with huge amounts of water & air to blow themselves up to several times their normal size. They do this to evade and scare of predators. On top of their bloating abilities, they also are one of the most poisonous fish in the sea... Also they are the only bony fish which can close their eyes!", 
        Hint = "Found in reefs and deepwaters.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = nil, 
        Price = 230, 
        XP = 100, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah! a Blowfish!", 
            "A Pufferfish!", 
            "A Water Balloon!", 
            "Woah, A Pufferfish!", 
            "Augh..."
        }, 
        SparkleColor = Color3.fromRGB(255, 227, 15), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ocean"
    }, 
    Swordfish = {
        WeightPool = {
            1000, 
            2500
        }, 
        Chance = 15, 
        Rarity = "Rare", 
        Resilience = 35, 
        Description = "Swordfish are extremely strong and notable due to their long flattened bill that resembles a sword, as their name implies. They are a great catch, and anglers around the globe are impressed by a Swordfish catch.", 
        Hint = "Found in deep ocean water. Extremely strong.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 850, 
        XP = 300, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Windy", 
            "Clear"
        }, 
        Quips = {
            "A Swordfish!", 
            "WOAH! A Swordfish!!", 
            "SWORDFISHHHH", 
            "I caught a swordfish!!", 
            "A Fish Sword..! A Fish Sword!"
        }, 
        SparkleColor = Color3.fromRGB(93, 128, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        ViewportSizeOffset = 0.9, 
        From = "Ocean"
    }, 
    Sailfish = {
        WeightPool = {
            400, 
            600
        }, 
        Chance = 16, 
        Rarity = "Rare", 
        Resilience = 40, 
        Description = "Sailfish are known for their incredible speed, long bill, and their striking sail-like dorsal fin. It's sleek body is built for fast swimming, allowing it to dart through water in bursts of speed. They are found in tropical and warmer ocean waters.", 
        Hint = "Found in ocean water. Extremely strong.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 800, 
        XP = 300, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Windy", 
            "Clear"
        }, 
        Quips = {
            "A Sailfish!", 
            "WOAH! A Sailfish!!", 
            "It's a Sailfish!", 
            "I caught a Sailfish!!"
        }, 
        SparkleColor = Color3.fromRGB(255, 242, 94), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        ViewportSizeOffset = 0.9, 
        From = "Ocean"
    }, 
    ["Cookiecutter Shark"] = {
        WeightPool = {
            5, 
            15
        }, 
        Chance = 40, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "The Cookiecutter Shark is a small, nocturnal shark with an unusual feeding habit- t bites circular chunks from larger animals, leaving a 'cookie-cutter' wound. They can be found primarily alongside sharks during shark hunts.", 
        Hint = "Found during a shark hunt during the night.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = "Night", 
        Price = 500, 
        XP = 300, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "A Cookiecutter Shark!", 
            "Woah, a Cookiecutter!", 
            "Nice, I can make some Gingerbread!", 
            "A Cookiecutter Shark!", 
            "I caught a Cookiecutter Shark!"
        }, 
        SparkleColor = Color3.fromRGB(255, 103, 103), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    ["Bull Shark"] = {
        WeightPool = {
            900, 
            1300
        }, 
        Chance = 0.3, 
        Rarity = "Legendary", 
        Resilience = 20, 
        Description = "Bull sharks have robust bodies, and an extremely powerful nature. They have a special ability to adapt to both saltwater and freshwater, which is quite rare for sharks. Bull Sharks can be found most commonly near coats, and in freshwaters.", 
        Hint = "Found roaming in all types of waters and on the coasts.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = nil, 
        Price = 400, 
        XP = 150, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Rain", 
            "Foggy"
        }, 
        Quips = {
            "A Bull Shark!", 
            "Thats some Bull Shark!", 
            "I caught a Bull Shark!"
        }, 
        SparkleColor = Color3.fromRGB(255, 245, 197), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "Ocean"
    }, 
    Moonfish = {
        WeightPool = {
            2500, 
            5000
        }, 
        Chance = 0.2, 
        Rarity = "Legendary", 
        Resilience = 20, 
        ProgressEfficiency = 0.6, 
        Description = "The Moonfish is a sizable, flat, bony fish that inhabits deep and occasionally warm waters. While their behaviour resembles that of the Ocean Sunfish, Moonfish are far more aggressive, using their rock-hard skulls to charge at fish, boats, and swimmers.", 
        Hint = "???", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Night", 
        Price = 1800, 
        XP = 900, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I think my backbone snapped..", 
            "Woah!!", 
            "OH MY! A MOONFISH?", 
            "A Moonfish!!", 
            "Woah, a Moonfish!!", 
            "How did I pull this up?", 
            "A Moonfish!!!"
        }, 
        SparkleColor = Color3.fromRGB(255, 122, 70), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean"
    }, 
    ["Crown Bass"] = {
        WeightPool = {
            20, 
            60
        }, 
        Chance = 0.2, 
        Rarity = "Legendary", 
        Resilience = 20, 
        ProgressEfficiency = 0.8, 
        Description = "The Crown Bass is a special type of bass that is known for its vibrant colours, and its luminescent 'crown' on its head. They use this crown to attract prey, and see easily at night. They can be found all over the world in all sorts of salt waters, especially warmer waters during the night.", 
        Hint = "In salt waters during the night. ", 
        FavouriteBait = "Squid", 
        FavouriteTime = "Night", 
        Price = 1200, 
        XP = 700, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Crown Bass!", 
            "I caught a Crown Bass!", 
            "Woah! A Crown Bass!", 
            "Ouu! A Crown Bass!"
        }, 
        SparkleColor = Color3.fromRGB(203, 163, 70), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    ["Flying Fish"] = {
        WeightPool = {
            15, 
            50
        }, 
        Chance = 0.15, 
        Rarity = "Legendary", 
        Resilience = 25, 
        ProgressEfficiency = 0.7, 
        Description = "The Flying Fish is a unique fish, renowned for their wing-like fins which give them the ability to soar above the ocean's surface. They use this ability to swiftly evade predators as well as dwelling near the surface to find small organisms to feed on.", 
        Hint = "In salt waters during the night. ", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Night", 
        Price = 1200, 
        XP = 700, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Flying Fish!", 
            "I caught a Flying Fish!", 
            "Woah! A Flying Fish!", 
            "Ouu! A Flying Fish!"
        }, 
        SparkleColor = Color3.fromRGB(172, 209, 255), 
        HoldAnimation = l_fish_0:WaitForChild("underweight"), 
        From = "Ocean"
    }, 
    Rabbitfish = {
        WeightPool = {
            25, 
            60
        }, 
        Chance = 1, 
        Rarity = "Legendary", 
        Resilience = 35, 
        ProgressEfficiency = 0.8, 
        Description = "The Rabbitfish is an elusive saltwater fish that is only found under The Arch. They are odd creatures that both resemble a rabbit, and swim in a pattern similar to a bunny jumping.", 
        Hint = "Found under The Arch.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = nil, 
        Price = 1100, 
        XP = 800, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah!! A Rabbitfish!", 
            "A Rabbit!!", 
            "I caught a Rabbitfish!"
        }, 
        SparkleColor = Color3.fromRGB(204, 142, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    Dolphin = {
        WeightPool = {
            1500, 
            2000
        }, 
        Chance = 0.8, 
        Rarity = "Legendary", 
        Resilience = 5, 
        ProgressEfficiency = 0.95, 
        Description = "The Dolphin is a playful, intelligent marine mammal known for its sleek body, curved dorsal fin, and high intelligence. Dolphins are fast swimmers, known for jumping out of the water in graceful arcs and interacting with boats and swimmers. Found in the ocean.", 
        Hint = "Found in the ocean.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 1200, 
        XP = 600, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I caught a Dolphin!", 
            "It's a Dolphin!", 
            "A DOLPHINN!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavybasic"), 
        From = "Ocean"
    }, 
    Sawfish = {
        WeightPool = {
            4000, 
            6000
        }, 
        Chance = 0.7, 
        Rarity = "Legendary", 
        Resilience = 10, 
        Description = "The Sawfish is a large, unique fish with a long, flattened snout that is lined with sharp teeth, resembling a saw. They are found all across the ocean mostly during the night.", 
        Hint = "found all around the ocean during the night.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Night", 
        Price = 1500, 
        XP = 900, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Sawfish!", 
            "Chainsawfish!", 
            "I caught a Sawfish!", 
            "Woah, a Sawfish!"
        }, 
        SparkleColor = Color3.fromRGB(161, 199, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean"
    }, 
    Oarfish = {
        WeightPool = {
            1500, 
            2500
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 15, 
        ProgressEfficiency = 0.7, 
        Description = "The Oarfish is a massive, snake-like creatures that dwell in the deep ocean. they are often mistaken for sea serpents or mythical creatures. Their presence is considered an omen by many ancient cultures.", 
        Hint = "???", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 4000, 
        XP = 2000, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "WOAH! An Oarfish!", 
            "I Caught an Oarfish!", 
            "It's an Oarfish!", 
            "Oar Oar Oar Oar Oar"
        }, 
        SparkleColor = Color3.fromRGB(255, 51, 51), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Ocean"
    }, 
    ["Great White Shark"] = {
        WeightPool = {
            7000, 
            12000
        }, 
        Chance = 2, 
        Rarity = "Mythical", 
        Resilience = 8, 
        ProgressEfficiency = 0.7, 
        Description = "Great White Sharks are apex predators and will put up an intense fight when hooked. Their presence is often a sign of rich, diverse marine life in the area. Rare and challenging, they offer one of the biggest rewards for those skilled enough to catch them.", 
        Hint = "Only rarely spotted in the oceans during a Shark Hunt.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = nil, 
        Price = 6000, 
        XP = 900, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "WOAH!! I CAUGHT A GREAT WHITE!", 
            "A GREAT WHITE??", 
            "HOLY.. A GREAT WHITE??", 
            "I CAN'T FEEL MY SPINE!!"
        }, 
        SparkleColor = Color3.fromRGB(93, 123, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean", 
        Shark = true
    }, 
    ["Great Hammerhead Shark"] = {
        WeightPool = {
            2300, 
            5000
        }, 
        Chance = 2, 
        Rarity = "Mythical", 
        Resilience = 20, 
        ProgressEfficiency = 0.65, 
        Description = "The Great Hammerhead Shark is a large, powerful predator known for its distinct hammer-shaped head. Its unique head shape improves its ability to track prey, making it a formidable hunter in the ocean, and a prominent catch among anglers.", 
        Hint = "Only rarely spotted in the oceans during a Shark Hunt. Only awake during the day.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Day", 
        Price = 5500, 
        XP = 860, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "WOAH!! I CAUGHT A GREAT HAMMERHEAD!", 
            "A GREAT HAMMERHEAD??", 
            "HOLY.. A GREAT HAMMERHEAD??", 
            "I CAN'T FEEL MY SPINE!!", 
            "HAMMERTIME!", 
            "Comically large hammer head!!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean", 
        Shark = true
    }, 
    ["Mythic Fish"] = {
        WeightPool = {
            6, 
            14
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 40, 
        ProgressEfficiency = 0.4, 
        Description = "The Mythic Fish is an extremely rare and beautiful fish. They swim gracefully in couples of two near the surface of the ocean water. They seem weak, but they can oddly put up a strong fight when being caught. This is due to the other Mythic Fish attempting to aid it's partner by pulling it off the hook.", 
        Hint = "Found in the Ocean.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 2000, 
        XP = 800, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Oh no.. Where is it's partner?", 
            "A Mythic Fish!!", 
            "I Caught a Mythic Fish!!!", 
            "NO WAY! A Mythic Fish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 199, 32), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Ocean"
    }, 
    ["Sea Pickle"] = {
        WeightPool = {
            4, 
            10
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 50, 
        Description = "The Sea Pickle is a quirky, small, tube-like sea creature found on ocean beds. Its glowing green body gives off a faint bioluminescent light, making it easy to spot at night. It's know to wriggle out of nets and rods, making it a tricky catch. Despite its unassuming appearance, it's highly valued for its oddity and unique glow.", 
        Hint = "Found in the ocean. Can be caught in rods and cages.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Night", 
        Price = 2000, 
        XP = 60, 
        Seasons = {
            "Autunn", 
            "Summer"
        }, 
        Weather = {
            "Clear", 
            "Cloudy"
        }, 
        Quips = {
            "A SEA PICKLE!!", 
            "I CAUGHT A SEA PICKLE!", 
            "A Sea pickle!"
        }, 
        SparkleColor = Color3.fromRGB(121, 255, 80), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Ocean"
    }, 
    ["Colossal Squid"] = {
        WeightPool = {
            7000, 
            12000
        }, 
        Chance = 0.02, 
        Rarity = "Mythical", 
        Resilience = 5, 
        ProgressEfficiency = 0.3, 
        Description = "The Colossal Squid is a massive, deep-sea creature with enormous tentacles and large appetite for anglers. Known for its incredible size and strength, it lurks in the deepest parts of the ocean, only occasionally venturing near the surface during the nights.", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = "Night", 
        Price = 6500, 
        XP = 3000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "WOAH. A COLOSSAL SQUID!!", 
            "MY BACCKK", 
            "I CAN'T BELIEVE IT! COLOSSAL SQUID!"
        }, 
        SparkleColor = Color3.fromRGB(255, 82, 82), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean"
    }, 
    ["Whale Shark"] = {
        WeightPool = {
            80000, 
            100000
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 50, 
        ProgressEfficiency = 0.3, 
        Description = "Whale Sharks are large but friendly sharks, as opposed to other sharks found in the Ocean. They are most active during the day, where they swim around in search of small organisms to eat. Despite being playful and harmless, they will still put up quite a hefty fight when hooked.", 
        Hint = "Only rarely spotted in the oceans during a Shark Hunt near the Desolate Deep.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Day", 
        Price = 6500, 
        XP = 3000, 
        Seasons = {
            "Summer", 
            "Autumn"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "WOAH! A WHALE SHARKKKK!", 
            "NO WAY!!", 
            "I CAUGHT A WHALE SHARK!!", 
            "WUHWUHWUHWUHWUHWHALE SHARK??!!"
        }, 
        SparkleColor = Color3.fromRGB(187, 190, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Ocean", 
        Shark = true
    }, 
    Chub = {
        WeightPool = {
            10, 
            30
        }, 
        Chance = 100, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Chub is a hardy and adaptable freshwater fish, typically found in Roslit Pond. The Chub is an easy catch for novice anglers and is thankfully a common catch.", 
        Hint = "commonly caught in Roslit Pond.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Day", 
        Price = 40, 
        XP = 40, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Chub!", 
            "Woah, a Chub!!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Perch = {
        WeightPool = {
            2, 
            12
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 70, 
        Description = "The Perch is a common freshwater fish that is best found in Roslit Bays fresh water. They are known for their striped bodies and a playful behaviour.", 
        Hint = "Found in freshwater of Roslit.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 70, 
        XP = 80, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Perch!", 
            "I caught a Perch!", 
            "Woah, a Perch!", 
            "Aww! A Perch!"
        }, 
        SparkleColor = Color3.fromRGB(119, 163, 77), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Minnow = {
        WeightPool = {
            1, 
            6
        }, 
        Chance = 60, 
        Rarity = "Common", 
        Resilience = 90, 
        Description = "Minnows are found in Roslit Bays pond and are easiest to find during the clear spring days. Minnows are commonly found in schools of 4 to 6 fish. They also create a great baitfish!", 
        Hint = "Lives in Roslit Bays pond. Very easy to catch with bagels.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = nil, 
        Price = 45, 
        XP = 75, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Ouu a Minnow!", 
            "Woah, a Minnow!", 
            "A Minnow!", 
            "I caught a Minnow!", 
            "Aw! I caught a Baitfish!"
        }, 
        SparkleColor = Color3.fromRGB(161, 161, 161), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Pearl = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 60, 
        Rarity = "Common", 
        Resilience = 100, 
        Description = "A common pearl with some imperfections.", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 60, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(255, 239, 231), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    Pumpkinseed = {
        WeightPool = {
            1, 
            5
        }, 
        Chance = 65, 
        Rarity = "Uncommon", 
        Resilience = 80, 
        Description = "Pumpkinseed are known for their distinctive red or orange edge on the ear flap and their round body shape. They prefer warmer waters and are often found in Roslit Bays freshwater. Pumpkinseed are also much less aggressive compared to other sunfish species.", 
        Hint = "Found in Roslit freshwater during warm days.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 90, 
        XP = 30, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Pumpkinseed!", 
            "I caught a Pumpkinseed!", 
            "Can it hear me?", 
            "Woah.. Cool ears!"
        }, 
        SparkleColor = Color3.fromRGB(255, 60, 60), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Clownfish = {
        WeightPool = {
            1, 
            6
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "The clownfish, known for its vibrant orange and white stripes, is a small, hardy reef dweller. Often found alongside coral and see anemones inside the reef of Roslit Bay.\t\t\tBest paired with the Blue Tang!", 
        Hint = "Found in Roslit Bays coral reef.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = nil, 
        Price = 90, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Ouu a Clownfish!", 
            "Woah, a Clownfish!", 
            "A Clownfish!", 
            "I caught a Clownfish!", 
            "I caught a Clownfish!", 
            "What kind of circus is this?"
        }, 
        SparkleColor = Color3.fromRGB(255, 167, 43), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    ["Blue Tang"] = {
        WeightPool = {
            3, 
            15
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 65, 
        Description = "The Blue Tang is most renowned for its vivid blue coloration and yellow tail. Often found alongside coral and see anemones inside the reef of Roslit Bay.\t\t\tBest paired with the Clownfish!", 
        Hint = "Found in Roslit Bays coral reef.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 90, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Blue Tang!", 
            "Woah, a Blue Tang!", 
            "A Blue Tang!", 
            "I caught a Blue Tang!", 
            "I caught a Blue Tang!", 
            "Found her!"
        }, 
        SparkleColor = Color3.fromRGB(48, 69, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Butterflyfish = {
        WeightPool = {
            2, 
            15
        }, 
        Chance = 40, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "Butterflyfish are vibrant reef fish known for their striking colors and elaborate patterns. They feed and behave similar to other fish found in Roslit Bays coral reef.", 
        Hint = "Found in Roslit Bays coral reef.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 110, 
        XP = 60, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "Ouu a Butterflyfish!", 
            "Woah, a Butterflyfish!", 
            "It's so pretty!"
        }, 
        SparkleColor = Color3.fromRGB(255, 249, 80), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    ["Gilded Pearl"] = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 25, 
        Rarity = "Unusual", 
        Resilience = 100, 
        Description = "A golden pearl with a shiny appearance... Could this hold special powers within it...?", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 120, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(255, 213, 108), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    Angelfish = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 60, 
        Description = "Angelfish are colorful and striking reef dwellers, known for their vibrant patterns and graceful swimming. Found in Roslit bays coral reef, they are a fun and elegant part of Roslits ecosystem.", 
        Hint = "Found in Roslit Bays coral reef.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 120, 
        XP = 60, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Ouu an Angelfish!", 
            "Woah, an Angelfish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Squid = {
        WeightPool = {
            5, 
            25
        }, 
        Chance = 25, 
        Rarity = "Unusual", 
        Resilience = 45, 
        Description = "Squids can be found best at night in the surrounding ocean of Roslit Bay. Squids are rapid swimmers and largely locate their prey by sight. Squids are extremely intelligent and can even hunt in cooperative groups.", 
        Hint = "Best found at night in ocean near Roslit Bay.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Night", 
        Price = 140, 
        XP = 95, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Squid!", 
            "A cute Squid!", 
            "I caught a Squid!"
        }, 
        SparkleColor = Color3.fromRGB(255, 173, 102), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    ["Ribbon Eel"] = {
        WeightPool = {
            5, 
            150
        }, 
        Chance = 12, 
        Rarity = "Unusual", 
        Resilience = 30, 
        Description = "The ribbon eel is a striking and elusive reef fish known for its vibrant blue or green body and long, ribbon-like appearance. While they are rare, the Ribbon Eel can be best found in the coral reef of Roslit Bay", 
        Hint = "Only comes out at night. Can be found inside the coral reef of Roslit Bay.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 150, 
        XP = 150, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Is it a snake?", 
            "A Ribbon Eel!", 
            "I think some slime got on me.", 
            "Woah! A Ribbon Eel!", 
            "H-eel-lo! Ribbon Eel!"
        }, 
        SparkleColor = Color3.fromRGB(70, 141, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Roslit"
    }, 
    ["Yellow Boxfish"] = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 18, 
        Rarity = "Unusual", 
        Resilience = 40, 
        Description = "Yellow Boxfish are known for their odd box-shaped body along with their vibrant yellow hue. Despite the cute appearance, they are incredibly toxic to the touch. They lurk around the coral reefs of Roslit Bay during the day.", 
        Hint = "Found in Roslit Bays coral reef.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Day", 
        Price = 140, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Ouu a Yellow Boxfish!", 
            "Woah, a Yellow Boxfish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 222, 57), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    Clam = {
        WeightPool = {
            9, 
            10
        }, 
        Chance = 60, 
        Rarity = "Unusual", 
        Resilience = 70, 
        Description = "The Clam is an interesting fish that is found behind Roslit Bay. They are quite sought after because they yield a valuable pearl once caught.", 
        Hint = "Found behind Roslit Bay.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = nil, 
        Price = 13, 
        XP = 25, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Clam!", 
            "I caught a Clam!", 
            "Woah, a Clam!", 
            "Wan go clam?"
        }, 
        SparkleColor = Color3.fromRGB(212, 126, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit"
    }, 
    ["Rose Pearl"] = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 25, 
        Rarity = "Unusual", 
        Resilience = 100, 
        Description = "A pearl with a powerful pink hue.", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 145, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(255, 201, 238), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    Arapaima = {
        WeightPool = {
            1000, 
            2000
        }, 
        Chance = 15, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "Arapaima are massive freshwater fish with large, broad bodies and a distinctive, armor-like scaled appearance. They have a unique respiratory system that allows them to breathe air, as well as gills.", 
        Hint = "Found in Roslit Bays freshwater during the day.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 250, 
        XP = 150, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain", 
            "Foggy"
        }, 
        Quips = {
            "An Arapaima!", 
            "I caught an Arapaima!", 
            "Woah, an Arapaima!"
        }, 
        SparkleColor = Color3.fromRGB(154, 39, 39), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Roslit"
    }, 
    ["Alligator Gar"] = {
        WeightPool = {
            200, 
            450
        }, 
        Chance = 45, 
        Rarity = "Rare", 
        Resilience = 40, 
        Description = "The Alligator Gar is a large, vicious freshwater fish that can be found in Roslit Bays pond. Gars track back to 100 million years ago, giving them the nickname as a 'living fossil'.", 
        Hint = "Can be found in lakes during summer.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 220, 
        XP = 100, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Gar!", 
            "It's an Alligator Gar!", 
            "A Gar!!", 
            "Woah, an Alligator Gar!", 
            "Aye!! A Gar!", 
            "Oh my Gar!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Roslit"
    }, 
    ["Suckermouth Catfish"] = {
        WeightPool = {
            95, 
            170
        }, 
        Chance = 35, 
        Rarity = "Rare", 
        Resilience = 60, 
        Description = "The Suckermouth Catfish is a tropical freshwater fish found on the ground and near the seaweed of Roslits Bays pond. They are easily notable for their large armour like scutes covering their upper parts of the head and body.", 
        Hint = "Found best near seaweed of Roslit Bays pond.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = "Day", 
        Price = 160, 
        XP = 80, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Suckermouth Catfish!", 
            "I caught a Catfish!", 
            "Woah, a Suckermouth!"
        }, 
        SparkleColor = Color3.fromRGB(158, 128, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Roslit"
    }, 
    ["Mauve Pearl"] = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 10, 
        Rarity = "Rare", 
        Resilience = 100, 
        Description = "A somber purple pearl.", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(197, 178, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    ["Dumbo Octopus"] = {
        WeightPool = {
            15, 
            40
        }, 
        Chance = 0.1, 
        Rarity = "Legendary", 
        Resilience = 30, 
        ProgressEfficiency = 0.85, 
        Description = "The Dumbo Octopus is a deep-sea dweller, named for its ear like fins that resemble the ears of Disney's famous elephant character. With a soft, gelatinous body and gentle movements, it glides through the oceans and coral reefs of Roslit Bay.", 
        Hint = "Caught in Roslit Bays coral reef.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 900, 
        XP = 400, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Woah, I caught a Dumbo!", 
            "A Dumbo Octopus!", 
            "No way! A Dumbo Octupus!"
        }, 
        SparkleColor = Color3.fromRGB(255, 142, 90), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Roslit"
    }, 
    Axolotl = {
        WeightPool = {
            5, 
            15
        }, 
        Chance = 0.05, 
        Rarity = "Legendary", 
        Resilience = 75, 
        ProgressEfficiency = 0.9, 
        Description = "Axolotls are small carnivorous creatures who reside in the Roslit Bay pond. They are nocturnal creatures and are known to hunt primarily worms. They are well known for their ability to regenerate and adorable faces.", 
        Hint = "Caught in Roslit Bays pond at night.", 
        FavouriteBait = "Insect", 
        FavouriteTime = "Night", 
        Price = 1000, 
        XP = 550, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "This an Axolotl..", 
            "An Axolotl!", 
            "It's so cute!", 
            "That's a cute axolotl!"
        }, 
        SparkleColor = Color3.fromRGB(255, 131, 131), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        ViewportSizeOffset = 2, 
        From = "Roslit"
    }, 
    ["Deep Pearl"] = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 5, 
        Rarity = "Legendary", 
        Resilience = 100, 
        Description = "A gloomy pearl embued with the essence of the deep ocean.", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 880, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(82, 39, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    ["Manta Ray"] = {
        WeightPool = {
            7750, 
            10000
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 10, 
        ProgressEfficiency = 0.9, 
        Description = "Manta Rays are very elegant and remarkably large creatures that coast alongside the coral reefs of Roslit Bay. They move their wing-like fins in a wavy motion to generate enough speed to guide through the ocean. Manta Rays typically feed on small fish during the night.", 
        Hint = "Found gliding through Roslit Bays coral reef during the night.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Night", 
        Price = 3000, 
        XP = 1000, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH.. A Manta Ray!", 
            "I caught a Manta Ray!", 
            "Woah.. A Manta Ray!!", 
            "Hol-ey Mol-ray!"
        }, 
        SparkleColor = Color3.fromRGB(87, 118, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Roslit"
    }, 
    ["Aurora Pearl"] = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 2.5, 
        Rarity = "Mythical", 
        Resilience = 100, 
        Description = "The colors and light of the Aurora Borealis is prevalent within this glowing pearl.", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 2250, 
        XP = 0, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(106, 255, 188), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    ["Golden Sea Pearl"] = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 0.2, 
        Rarity = "Exotic", 
        Resilience = 100, 
        Description = "A strikingly shiny pearl, rumored to have originated from the deepest depths of Atlantis.", 
        Hint = "From catching Clams.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 3500, 
        XP = 600, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {}, 
        SparkleColor = Color3.fromRGB(255, 228, 130), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit", 
        IsPearl = true
    }, 
    Basalt = {
        WeightPool = {
            150, 
            210
        }, 
        Chance = 55, 
        Rarity = "Trash", 
        Resilience = 120, 
        Description = "Basalt, also known as Lava Rock, is an igneous volcanic rock that forms when molten lava cools and solidifies. Very common to find when in a volcanic area.", 
        Hint = "Found in active Volcanoes", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 15, 
        XP = 10, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "Uhmm..?", 
            "Some Basalt!", 
            "Oh. A Piece of Basalt.", 
            "It's!- Oh.. Basalt..", 
            "Basalt.."
        }, 
        SparkleColor = Color3.fromRGB(59, 59, 59), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit Volcano"
    }, 
    ["Volcanic Geode"] = {
        WeightPool = {
            200, 
            200
        }, 
        Chance = 17, 
        Rarity = "Rare", 
        Resilience = 120, 
        Description = "The Volcanic Geode encases a magma crystal core, preserving its contents with an amber-like quality. Within this geode, you might find a trove of rare or extinct treasures\226\128\148 it's like a volcanic Christmas!", 
        Hint = "Chipped off a volcanic geode.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        BuyMult = 3, 
        Price = 200, 
        XP = 20, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ooo, shiny!", 
            "A rock...?!", 
            "Woah! Glowy thing!", 
            "A Geode!", 
            "What's this thing?"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("crate"), 
        IsCrate = true, 
        CrateType = "All", 
        BaitContents = {
            "Coal", 
            "Coal", 
            "Coal", 
            "Coal", 
            "Maggot", 
            "Maggot", 
            "Minnow", 
            "Truffle Worm", 
            "Coal", 
            "Night Shrimp", 
            "Rapid Catcher", 
            "instant Catcher", 
            "Super Flakes", 
            "Night Shrimp", 
            "Rapid Catcher", 
            "Super Flakes"
        }, 
        FishContents = {
            "Ember Snapper", 
            "Pyrogrub", 
            "Sturgeon", 
            "Magma Tang", 
            "Alligator Gar", 
            "Pufferfish", 
            "Sea Urchin", 
            "Sea Urchin", 
            "Perch", 
            "Perch", 
            "Perch", 
            "Angelfish", 
            "Rock", 
            "Rock", 
            "Rock", 
            "Magma Tang"
        }, 
        CoinContents = {
            150, 
            500
        }, 
        From = "Roslit Volcano"
    }, 
    ["Magma Tang"] = {
        WeightPool = {
            6, 
            30
        }, 
        Chance = 50, 
        Rarity = "Uncommon", 
        Resilience = 40, 
        Description = "The Magma Tang is a rare lava imbued Tang with a resting body temperature of 950C. They are extremely common in the lava, as they practically are part of the lava.", 
        Hint = "Found in Roslit Volcano during the day.", 
        FavouriteBait = "Coal", 
        FavouriteTime = "Day", 
        Price = 130, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Blue Tang!", 
            "Woah, a Blue Tang!", 
            "A Blue Tang!", 
            "I caught a Blue Tang!", 
            "I caught a Blue Tang!", 
            "Found her!.. But evil!"
        }, 
        SparkleColor = Color3.fromRGB(255, 158, 73), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit Volcano"
    }, 
    ["Ember Snapper"] = {
        WeightPool = {
            60, 
            120
        }, 
        Chance = 50, 
        Rarity = "Unusual", 
        Resilience = 40, 
        Description = "The Ember Snapper is a lava swimming fish with a resemblance to the salt water 'Red Snapper'. The Ember Snapper is acute in volcanic habitats due to their thick skin and strong dorsal fins.", 
        Hint = "Found in volcanic regions.", 
        FavouriteBait = "Coal", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 120, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "An Ember Snapper!", 
            "Woah! I caught an Ember Snapper!", 
            "I caught an Ember Snapper!", 
            "Ember Snapper!!!", 
            "It burns!"
        }, 
        SparkleColor = Color3.fromRGB(191, 39, 25), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Roslit Volcano"
    }, 
    ["Ember Perch"] = {
        WeightPool = {
            4, 
            15
        }, 
        Chance = 80, 
        Rarity = "Unusual", 
        Resilience = 40, 
        Description = "The Ember Perch is a lava swimming fish with a resemblance to the fresh water 'Perch'. The Ember Perch is acute in volcanic habitats due to their thick skin and ability to turn coal and carbon into a food source.", 
        Hint = "Found in volcanic regions.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 160, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "An Ember Perch!", 
            "I caught a Perch!.. Why is it so hot?", 
            "Woah, a Perch! Why is it on fire?", 
            "Aww! An Ember Perch!", 
            "Woah! An Ember Perch!"
        }, 
        SparkleColor = Color3.fromRGB(255, 19, 19), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Roslit Volcano"
    }, 
    Pyrogrub = {
        WeightPool = {
            300, 
            600
        }, 
        Chance = 25, 
        Rarity = "Rare", 
        Resilience = 25, 
        ProgressEfficiency = 0.8, 
        Description = "The Pyrogrub is a fearsome, lava swimming eel that thrives in the most volcanic of environments. The Pyrogrub sports thick dragon-like scales which allow it's inner body to not react to any form of outside temperature.", 
        Hint = "Found in volcanic regions.", 
        FavouriteBait = "Coal", 
        FavouriteTime = nil, 
        Price = 340, 
        XP = 120, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Pyrogrub!", 
            "I caught a Pyrogrub!", 
            "Woah, a Pyrogrub!", 
            "What the?!"
        }, 
        SparkleColor = Color3.fromRGB(255, 151, 46), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Roslit Volcano"
    }, 
    ["Obsidian Salmon"] = {
        WeightPool = {
            40, 
            180
        }, 
        Chance = 3, 
        Rarity = "Legendary", 
        Resilience = 15, 
        ProgressEfficiency = 0.9, 
        Description = "The Obsidian Salmon is an extremely rare breed of Sockeye Salmon. The Obsidian Salmon breeds extremely deep in the heart of Roslit Volcano. They are extremely strong and are twice as dense as a common Sockeye Salmon.", 
        Hint = "???", 
        FavouriteBait = "Coal", 
        FavouriteTime = "Night", 
        Price = 600, 
        XP = 300, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Obsidian Salmoff!", 
            "Woah! An Obsidian Salmon!", 
            "Awesome! An Obsidian Salmon", 
            "An Obsidian Salmon!", 
            "Woah, An Obsidian Salmon!", 
            "A Salmon!..? Made of obsidian?"
        }, 
        SparkleColor = Color3.fromRGB(102, 0, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Roslit Volcano"
    }, 
    ["Obsidian Swordfish"] = {
        WeightPool = {
            1000, 
            2500
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 20, 
        ProgressEfficiency = 0.8, 
        Description = "Swordfish are extremely strong and notable due to their long flattened bill that resembles a sword, as their name implies. This swordfish has adapted to it's magma filled life, and is now imbued with Obsidian skin.", 
        Hint = "???", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 2500, 
        XP = 1000, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Windy", 
            "Clear"
        }, 
        Quips = {
            "An Obsidian Swordfish!", 
            "WOAH! An Obsidian Swordfish!!", 
            "OBSIDIANNN SWORDFISHHHH", 
            "I caught an Obsidian Swordfish!!"
        }, 
        SparkleColor = Color3.fromRGB(176, 79, 255), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        ViewportSizeOffset = 0.9, 
        From = "Roslit Volcano"
    }, 
    ["Molten Banshee"] = {
        WeightPool = {
            3000, 
            5500
        }, 
        Chance = 0.01, 
        Rarity = "Exotic", 
        Resilience = 40, 
        ProgressEfficiency = 0.65, 
        Description = "The Molten Banshee is a complex fish of unknown terrestrial origin, that has resided inside the Roslit Volcano. It possesses a torpedo-like body with many sharp mandibles and scorching hot encrustments. They are rumored to have possibly come from another planet, and may be a bio-mechanical lifeform.", 
        Hint = "???", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = nil, 
        Price = 6500, 
        XP = 2000, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Molten Banshee!", 
            "WOAH! A Molten Banshee!!", 
            "MOLTEN BANSHEEEEEEEEE", 
            "I caught a Molten Banshee!!"
        }, 
        SparkleColor = Color3.fromRGB(255, 92, 28), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Roslit Volcano"
    }, 
    Ice = {
        WeightPool = {
            40, 
            60
        }, 
        Chance = 35, 
        Rarity = "Trash", 
        Resilience = 90, 
        Description = "Chunk of ice that broke off from a glacier in Snowcap. Kinda fun to lick..", 
        Hint = "Found in frozen bodies of water.", 
        FavouriteBait = "Magnet", 
        FavouriteTime = nil, 
        Price = 15, 
        XP = 10, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ermm..?", 
            "Uhmm..?", 
            "A block of Ice!", 
            "Oh. Ice.", 
            "Ouu! Let me lick it!", 
            "Ice..", 
            "It's not a popsicle, but it will do!"
        }, 
        SparkleColor = Color3.fromRGB(171, 255, 245), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    Bluegill = {
        WeightPool = {
            1, 
            6
        }, 
        Chance = 85, 
        Rarity = "Common", 
        Resilience = 90, 
        Description = "A small, round freshwater fish with bright blue and orange hues, easily recognized by its distinct gill spot. It can be found all over the waters of Snowcap.", 
        Hint = "Found in saltwater\226\128\153s near Snowcap.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 60, 
        XP = 90, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Bluegill!", 
            "But I pinked the Red Pill!", 
            "I caught a Bluegill!!", 
            "Lovely, a Bluegill!"
        }, 
        SparkleColor = Color3.fromRGB(149, 255, 188), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    Grayling = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 70, 
        Description = "An interesting, cold-water fish with shimmering silver scales and a signature large, colourful dorsal fin. It is known for it's beauty and its agile swimming behaviour. The Grayling is often found in Snowcap Pond during the day, but it can rarely be found at night.", 
        Hint = "Found in Snowcap Pond during the day.", 
        FavouriteBait = "Insect", 
        FavouriteTime = "Day", 
        Price = 80, 
        XP = 100, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Grayling!", 
            "I caught a Grayling!", 
            "Oh, a Grayling!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    ["Red Drum"] = {
        WeightPool = {
            10, 
            25
        }, 
        Chance = 40, 
        Rarity = "Common", 
        Resilience = 50, 
        Description = "The Red Drum is a close relative to the Black Drum Red Drum can be found all around Snowcaps vast salt-waters.", 
        Hint = "Found in salt-water of Snowcap.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 80, 
        XP = 50, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Red Drum!", 
            "I caught a Red Drum!", 
            "Woah, a Drum!", 
            "It'a Red Drum!", 
            "All I see is Red Drum."
        }, 
        SparkleColor = Color3.fromRGB(255, 49, 49), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    Herring = {
        WeightPool = {
            5, 
            11
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Herring is a slender silvery fish known for its schooling behaviour. Herring can often be found in costal waters during the day.", 
        Hint = "Found commonly in the coast of Snowcaps salt-water during the day.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Day", 
        Price = 70, 
        XP = 50, 
        Seasons = {
            "Summer", 
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Windy"
        }, 
        Quips = {
            "A Herring!", 
            "I caught a Herring!", 
            "Oh, a Herring!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    Pollock = {
        WeightPool = {
            10, 
            50
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 60, 
        Description = "Pollock are sleek, silver fish with a light belly contrasting a darker dorsal. They are fast swimmers and often found feeding under Snowcap Islands docks.", 
        Hint = "Found in Snowcap island, especially near the docks.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 70, 
        XP = 50, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Foggy", 
            "Rain"
        }, 
        Quips = {
            "A Pollock!", 
            "I caught a Pollock!", 
            "Woah, a Pollock!", 
            "Look! A Pollock!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    ["Arctic Char"] = {
        WeightPool = {
            20, 
            60
        }, 
        Chance = 40, 
        Rarity = "Uncommon", 
        Resilience = 50, 
        Description = "The Arctic Char is a striking fish commonly known for its vibrant reddish-orange belly and long mouth. They can be found in the cold salt-waters of Snowcap Island.", 
        Hint = "Found in open salt-water near Snowcap.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 80, 
        XP = 50, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Char!", 
            "I caught an Arctic Char!", 
            "Woah, a Char!", 
            "It's an Arctic Char!"
        }, 
        SparkleColor = Color3.fromRGB(255, 83, 83), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    Burbot = {
        WeightPool = {
            10, 
            35
        }, 
        Chance = 50, 
        Rarity = "Uncommon", 
        Resilience = 50, 
        Description = "The Burbot is a long, slender freshwater fish with a mottled brown and green appearance, resembling a cross between a catfish and an eel. Burbots are known for being active in colder temperatures, particularly under the ice in Snowcap Pond.", 
        Hint = "Found in Snowcap Pond.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 80, 
        XP = 110, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Burbot!", 
            "I caught a Burbot!", 
            "Oh, a Burbot!"
        }, 
        SparkleColor = Color3.fromRGB(194, 255, 129), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    Blackfish = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 80, 
        Rarity = "Uncommon", 
        Resilience = 60, 
        Description = "Blackfish are small, black, nighttime swimmers that can be most commonly found in the cold the rocky waters of Snowcap Pond.", 
        Hint = "Found in Snowcap Pond during the night.", 
        FavouriteBait = "Worm", 
        FavouriteTime = "Night", 
        Price = 100, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Blackfish!", 
            "I caught a Blackfish!", 
            "Oh, a Blackfish!"
        }, 
        SparkleColor = Color3.fromRGB(113, 113, 113), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    ["Skipjack Tuna"] = {
        WeightPool = {
            70, 
            160
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 45, 
        Description = "The Skipjack Tuna can be caught near Snowcap Island. They are extremely agile swimmers, allowing them to put up a strong fight against anglers.", 
        Hint = "Found near Snowcap Island.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 150, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Tuna!", 
            "A Skipjack Tuna!", 
            "Woah, a Skipjack Tuna!", 
            "I caught a Skipjack Tuna!"
        }, 
        SparkleColor = Color3.fromRGB(162, 174, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    ["Glacier Pike"] = {
        WeightPool = {
            12, 
            35
        }, 
        Chance = 45, 
        Rarity = "Unusual", 
        Resilience = 55, 
        Description = "Pikes are a long, predatory freshwater fish known for its aggressive nature and sharp teeth. Glacier Pikes are supremely found in cold freshwaters in Snowcap Island. They can be determined by their unique ice-coloured scales and longer fins.", 
        Hint = "Found in Snowcaps freshwater. Seems to prefer insect baits.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 230, 
        XP = 90, 
        Seasons = {
            "Autumn", 
            "Spring"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Glacier Pike!", 
            "I caught a Glacier Pike!", 
            "Woah! a Glacier Pike!", 
            "GLACIER PIKE!!!", 
            "I'd prefer a lance.", 
            "A Glacier Pike?!", 
            "That's a big Glacier Pike!"
        }, 
        SparkleColor = Color3.fromRGB(93, 140, 109), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    Lingcod = {
        WeightPool = {
            40, 
            140
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 50, 
        ProgressEfficiency = 0.95, 
        Description = "A large, aggressive predator with mottled brown and green skin, known for its sharp teeth and oddly fierce fighting behaviour when hooked. They can be found in ocean water near Snowcap during the day. They are especially active near the water-side enterance of Snowcap Cave.", 
        Hint = "Found in Snowcaps ocean water during the day. Especially active near the water-side enterance of Snowcap Cave.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = "Day", 
        Price = 110, 
        XP = 80, 
        Seasons = {
            "Autumn", 
            "Summer"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "I caught a Lingcod!", 
            "Woah! this is freaky!", 
            "A Lingcod!", 
            "It's a Lingcod!"
        }, 
        SparkleColor = Color3.fromRGB(76, 115, 55), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    Sturgeon = {
        WeightPool = {
            200, 
            800
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 35, 
        Description = "A massive, ancient fish with a long, armoured body and distinctive bony plates. Sturgeons are known for their size and strength, making them challenging to catch.", 
        Hint = "found in Snowcap Pond.", 
        FavouriteBait = "Seaweed", 
        FavouriteTime = nil, 
        Price = 300, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A Sturgeon!", 
            "I AMM.. I AMM A STURGEON!!", 
            "I caught a Sturgeon Fish!", 
            "A Sturgeon!!", 
            "Woahh a Sturgeon!"
        }, 
        SparkleColor = Color3.fromRGB(232, 232, 232), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    ["Pond Emperor"] = {
        WeightPool = {
            1000, 
            2500
        }, 
        Chance = 0.05, 
        Rarity = "Legendary", 
        Resilience = 25, 
        ProgressEfficiency = 0.6, 
        Description = "Pond Emperors are highly territorial, powerful swimmers that will consume almost anything. Their striking coloration, aggressive nature, and rare appearances make them a prized and fortunate catch for anglers.", 
        Hint = "Found in Snowcap Pond.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 900, 
        XP = 700, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Pond Emperor!", 
            "WOAH! A Pond Emperor!!", 
            "Pond Emperor!", 
            "I caught a Pond Emperor!!"
        }, 
        SparkleColor = Color3.fromRGB(136, 39, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    Ringle = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 80, 
        ProgressEfficiency = 0.5, 
        Description = "The Ringle is an interesting and elusive fish that swims at extremely low and cold depths. They have a Rhino-like horn that they use to attack their prey. Most commonly found in the open ocean of Snowcap Island.", 
        Hint = "Found in the open ocean of Snowcap Island during the night.", 
        FavouriteBait = "Bagel", 
        FavouriteTime = "Night", 
        Price = 900, 
        XP = 500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "A Ringle!", 
            "I caught a Ringle!", 
            "A Ringle!!", 
            "Woah, a Ringle!"
        }, 
        SparkleColor = Color3.fromRGB(87, 224, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Snowcap"
    }, 
    Glacierfish = {
        WeightPool = {
            400, 
            600
        }, 
        Chance = 0.02, 
        Rarity = "Mythical", 
        Resilience = 10, 
        ProgressEfficiency = 0.85, 
        Description = "Glacierfish are cold saltwater fish with large, broad bodies and a distinctive pink fin colouration. They are an extremely rare fish and can sometimes be a difficult catch for any angler. They can be found more commonly in Snowcap Caves during the night.", 
        Hint = "Found in Snowcap Caves during the night. Big fan of the Truffle Worm.", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = "Night", 
        Price = 800, 
        XP = 400, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain", 
            "Foggy"
        }, 
        Quips = {
            "A Glacierfish!", 
            "I caught a Glacierfish!", 
            "Woah, a Glacierfish!", 
            "It's beautiful..!"
        }, 
        SparkleColor = Color3.fromRGB(161, 233, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Snowcap"
    }, 
    Sweetfish = {
        WeightPool = {
            2, 
            5
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 85, 
        Description = "The Sweetfish is known for its delicate sweet flavour, and its golden hue. They are very commonly found in short river-like gap of Sunstone Island.", 
        Hint = "Found in the centre gap of Sunstone Island.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 40, 
        XP = 25, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Sweetfish!", 
            "Is there a sour one?", 
            "Woah! A Sweetfish!", 
            "Hope it's not artificially sweet!"
        }, 
        SparkleColor = Color3.fromRGB(157, 255, 96), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Sunstone"
    }, 
    Glassfish = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 90, 
        Rarity = "Common", 
        Resilience = 90, 
        Description = "The glassfish is a small, transparent fish with a delicate, almost invisible body that makes it well-suited for avoiding predators. It is a common find within the waters of Sunstone Island.", 
        Hint = "Found in Sunstone Island.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = nil, 
        Price = 45, 
        XP = 50, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Ouu a Glassfish!", 
            "Woah, a Glassfish!", 
            "I can barely see it!"
        }, 
        SparkleColor = Color3.fromRGB(126, 126, 126), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Sunstone"
    }, 
    ["Longtail Bass"] = {
        WeightPool = {
            20, 
            40
        }, 
        Chance = 50, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "The Longtail Bass is a striking species known for its elongated tail fin and vibrant coloration. It can be found all over the ocean, and is also a common catch of Sunstone Island!", 
        Hint = "Found in open ocean water and in Sunstone.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = nil, 
        Price = 120, 
        XP = 70, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Longtail Bass!", 
            "I caught a Longtail Bass!"
        }, 
        SparkleColor = Color3.fromRGB(255, 89, 89), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Sunstone"
    }, 
    ["Red Tang"] = {
        WeightPool = {
            3, 
            15
        }, 
        Chance = 55, 
        Rarity = "Uncommon", 
        Resilience = 65, 
        Description = "The Red Tang is a relatively common catch within Sunstone Island. Very similar to other Tangs such as the Blue Tang, just red!", 
        Hint = "Found in Sunstone Island.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = nil, 
        Price = 100, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ouu a Red Tang!", 
            "Woah, a Red Tang!", 
            "A Red Tang!", 
            "I caught a Red Tang!", 
            "I caught a Red Tang!", 
            "Found her!.. But red!"
        }, 
        SparkleColor = Color3.fromRGB(255, 82, 82), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Sunstone"
    }, 
    Chinfish = {
        WeightPool = {
            20, 
            40
        }, 
        Chance = 70, 
        Rarity = "Uncommon", 
        Resilience = 80, 
        Description = "The Chinfish is a peculiar species with a distinct chin-like protrusion on its lower jaw. They are sluggish swimmers and are an interesting catch to have on the other side of your line.", 
        Hint = "Caught near Sunstone Island.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 85, 
        XP = 40, 
        Seasons = {
            "Autumn", 
            "Winter"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "Woah, a Chinfish!", 
            "The Megachin!", 
            "I caught a Chinfish!", 
            "It's a Chinfish!", 
            "It's mewing!?"
        }, 
        SparkleColor = Color3.fromRGB(214, 214, 214), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Sunstone"
    }, 
    Trumpetfish = {
        WeightPool = {
            9, 
            20
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 60, 
        Description = "The Trumpetfish is a long, slender fish known for its tubular body and pointed snout. Its unique shape makes it a fascinating sight for visitors of Sunstone.", 
        Hint = "Found in the waters near Sunstone Island during the day.", 
        FavouriteBait = "Shrimp", 
        FavouriteTime = "Day", 
        Price = 100, 
        XP = 80, 
        Seasons = {
            "Autumn", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, a Trumpetfish!", 
            "Baby Keem!", 
            "What a catch!", 
            "Holy.. This thing is weird.."
        }, 
        SparkleColor = Color3.fromRGB(247, 255, 98), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Sunstone"
    }, 
    ["Mahi Mahi"] = {
        WeightPool = {
            70, 
            150
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 30, 
        Description = "The Mahi Mahi is a vibrant, fast-swimming fish known for its striking colors of blue, green, and yellow. They can be found all around Sunstone island, and is prized by many anglers.", 
        Hint = "Found near Sunstone Island.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 150, 
        XP = 90, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Windy"
        }, 
        Quips = {
            "I caught a Mahi Mahi!", 
            "Woah, a Mahi Mahi!!", 
            "It's a Mahi Mahi!"
        }, 
        SparkleColor = Color3.fromRGB(255, 249, 89), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Sunstone"
    }, 
    Napoleonfish = {
        WeightPool = {
            250, 
            350
        }, 
        Chance = 19, 
        Rarity = "Rare", 
        Resilience = 40, 
        Description = "The Napoleonfish, also known as the Humphead Wrasse, is a large and brightly coloured fish with a distinctive bump on its forehead. Despite its size, it is surprisingly agile, making it a thrilling challenge for anglers.", 
        Hint = "Found easier in the outer waters of Sunstone Island during the day.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 200, 
        XP = 100, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "A Napoleonfish!", 
            "I caught a Napoleonfish!", 
            "Woahh, a Napoleonfish!"
        }, 
        SparkleColor = Color3.fromRGB(90, 255, 195), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Sunstone"
    }, 
    Sunfish = {
        WeightPool = {
            4000, 
            10000
        }, 
        Chance = 1, 
        Rarity = "Legendary", 
        Resilience = 70, 
        ProgressEfficiency = 0.4, 
        Description = "Sunfish are the heaviest bony fish species alive today. Common sunfish can weigh up to one metric tonne but on rare instances they can way two metric tonnes! The largest appeal of the ocean Sunfish is the unusual shape of it's body and it's astonishing weight. Sunfish have the name for their love of basking in the sun by floating to the surface of the water.", 
        Hint = "Caught near Sunstone Island and can sometimes weigh over 1,000 kg.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 1500, 
        XP = 550, 
        Seasons = {
            "Summer"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "I think my backbone snapped..", 
            "Woah!!", 
            "OH MY! A SUNFISH?", 
            "A sunfish!", 
            "Woah, a Sunfish!", 
            "Nice tan..", 
            "How did I pull this up?", 
            "A SUNFISH!", 
            "MOLA MOLA!"
        }, 
        SparkleColor = Color3.fromRGB(255, 232, 99), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Sunstone"
    }, 
    Wiifish = {
        WeightPool = {
            200, 
            400
        }, 
        Chance = 1, 
        Rarity = "Legendary", 
        Resilience = 40, 
        ProgressEfficiency = 0.8, 
        Description = "The Wiifish is a legendary tropic fish that can only be found in the saltwater\226\128\153s Sunstone Island during the day. They are an extremely old fish, dating back over 230,000,000 years ago. While the Wiifish is a slow swimmer, they can put up an immense fight for even advanced anglers.", 
        Hint = "Found rarely near Sunstone Island during the day.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 1200, 
        XP = 500, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, a Wiifish!", 
            "This thing is super ancient!", 
            "A Wiifish!!", 
            "This brings me back!"
        }, 
        SparkleColor = Color3.fromRGB(255, 136, 51), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Sunstone"
    }, 
    Voltfish = {
        WeightPool = {
            8, 
            16
        }, 
        Chance = 0.01, 
        Rarity = "Mythical", 
        Resilience = 30, 
        ProgressEfficiency = 0.4, 
        Description = "The Voltfish is a lightning-fast relative of the Mythic Fish. They swim solo near the surface of the waters surrounding Sunstone, and make sporadic movements when hooked.", 
        Hint = "Found swimming near Sunstone Island during the Night.", 
        FavouriteBait = "Super Flakes", 
        FavouriteTime = "Night", 
        Price = 2200, 
        XP = 850, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A Voltfish!", 
            "Woah, a Voltfish!", 
            "Ouu! A Voltfish!", 
            "It zapped me!"
        }, 
        SparkleColor = Color3.fromRGB(255, 154, 71), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Sunstone"
    }, 
    ["Smallmouth Bass"] = {
        WeightPool = {
            5, 
            17
        }, 
        Chance = 75, 
        Rarity = "Common", 
        Resilience = 80, 
        Description = "The Smallmouth Bass is a popular freshwater fish known for its fighting spirit and preference for clear, cool waters. It has a streamlined body with a greenish-brown coloration and distinctive horizontal stripes.  It can be found in plenty of freshwaters, but is native to Terrapin Islands filtered water.", 
        Hint = "Can be found in freshwaters and in the filtered waters of Terrapin Island.", 
        FavouriteBait = "Worm", 
        FavouriteTime = nil, 
        Price = 70, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "A Smallmouth Bass!", 
            "I caught a Smallmouth Bass!", 
            "Woah! A Smallmouth Bass!", 
            "Ouu! A Bass!"
        }, 
        SparkleColor = Color3.fromRGB(127, 255, 88), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    Gudgeon = {
        WeightPool = {
            1, 
            3
        }, 
        Chance = 80, 
        Rarity = "Common", 
        Resilience = 100, 
        Description = "The Gudgeon is an extremely small, slender fish. They are adaptable and can thrive in a variety of freshwater environments but are native and commonly found near Terrapin Island.", 
        Hint = "Found in the water of Terrapin Island.", 
        FavouriteBait = "Insect", 
        FavouriteTime = "Day", 
        Price = 40, 
        XP = 10, 
        Seasons = {
            "Spring, Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I can barely see it!", 
            "A Gudgeon.!", 
            "Oh, cool!"
        }, 
        SparkleColor = Color3.fromRGB(216, 251, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    ["White Bass"] = {
        WeightPool = {
            3, 
            25
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "The White Bass is a slender, silvery fish with horizontal black stripes running along its body. It can be found in plenty of freshwaters, but is native to Terrapin Islands filtered water.", 
        Hint = "Can be found in freshwaters and in the filtered waters of Terrapin Island during the day.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = "Day", 
        Price = 110, 
        XP = 50, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A White Bass!", 
            "I caught a White Bass!", 
            "Woah! A White Bass!", 
            "Ouu! A Bass!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    Walleye = {
        WeightPool = {
            18, 
            40
        }, 
        Chance = 60, 
        Rarity = "Uncommon", 
        Resilience = 70, 
        Description = "The Walleye is a predatory fish known for its sharp teeth and distinctive large eyes. The Walleye can be found around the East side of Terrapin Island.", 
        Hint = "Can be found near Terrapin Island.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 90, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah! A Walleye!", 
            "I caught a Walleye!", 
            "Lovely, a Walleye!"
        }, 
        SparkleColor = Color3.fromRGB(113, 188, 96), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    ["Redeye Bass"] = {
        WeightPool = {
            3, 
            15
        }, 
        Chance = 40, 
        Rarity = "Unusual", 
        Resilience = 50, 
        Description = "The Redeye Bass looks very similar to the Largemouth Bass. However, the Redeye bass has very distinct red or orange eyes to go along with its greenish brown body.", 
        Hint = "Can be found in freshwaters and in the filtered waters of Terrapin Island during the day.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 115, 
        XP = 100, 
        Seasons = {
            "Spring", 
            "Autumn"
        }, 
        Weather = {
            "Windy"
        }, 
        Quips = {
            "A Redeyed Bass!", 
            "I caught a Redeye Bass!", 
            "Woah! A Redeye Bass!", 
            "Ouu! A Redeye Bass!"
        }, 
        SparkleColor = Color3.fromRGB(255, 29, 29), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    ["Chinook Salmon"] = {
        WeightPool = {
            100, 
            400
        }, 
        Chance = 30, 
        Rarity = "Unusual", 
        Resilience = 50, 
        Description = "The Chinook Salmon, also known as King Salmon, are large silver fish with a slightly forked tail and a black mouth. They are highly prized and are a common target for sport and commercial fishing. The King Salmon are commonly in ocean waters, but during the Autumn they migrate to Terrapin Island to lay eggs.", 
        Hint = "Found in the waters of Terrapin Island, and general ocean waters.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 230, 
        XP = 100, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Ou! A Chinook Salmon!", 
            "A King Salmon!", 
            "I Caught a King Salmon!", 
            "Woah, a King Salmon!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Terrapin"
    }, 
    ["King Oyster"] = {
        WeightPool = {
            4, 
            10
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 95, 
        Description = "King Oysters are a special breed of oysters that can only be found around Terrapin Island. They filter almost all salt out of the water, making Terrapins water freshwater.", 
        Hint = "Can be easily caught while cage fishing. Only found near Terrapin Island.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 35, 
        Seasons = {
            "Summer", 
            "autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "An Oyster!", 
            "Woah! A King Oyster", 
            "Awesome!", 
            "A King Oyster!", 
            "Ou! A King Oyster!"
        }, 
        SparkleColor = Color3.fromRGB(217, 215, 151), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    ["Golden Smallmouth Bass"] = {
        WeightPool = {
            15, 
            45
        }, 
        Chance = 4, 
        Rarity = "Legendary", 
        Resilience = 55, 
        Description = "A special and extremely rare breed of the Smallmouth Bass. They are extremely scarce in quantity, but they have slightly more haste and resilience than their cousins. Can be found alongside the Common Smallmouth Bass.", 
        Hint = "Swims fiercely in freshwater alongside their cousin the Smallmouth Bass.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Day", 
        Price = 700, 
        XP = 250, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Now, where's the cymbol?", 
            "A Golden Bass??", 
            "Golden Bass!", 
            "A Golden Smallmouth Bass!", 
            "A Gold Bass!", 
            "I usually wear silver.", 
            "So shiny! A Golden Bass!"
        }, 
        SparkleColor = Color3.fromRGB(255, 205, 3), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Terrapin"
    }, 
    Olm = {
        WeightPool = {
            1, 
            4
        }, 
        Chance = 2, 
        Rarity = "Legendary", 
        Resilience = 80, 
        ProgressEfficiency = 0.95, 
        Description = "The Olm is an aquatic salamander which is an exclusively cave-dwelling species. The olm is mostly found in dark and moist areas of freshwater. They are most notable for their adaptations to a life of darkness with-in their caves. The Olm has severely under underdeveloped eyes, leaving it blind. This blindness gives them an acute sense of smell and hearing.", 
        Hint = "Resides on the floor of caves and dark rocky areas. Loves the night.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = "Night", 
        Price = 900, 
        XP = 500, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear", 
            "Foggy"
        }, 
        Quips = {
            "An Olm!", 
            "I caught an Olm!", 
            "Olm.. my gosh!", 
            "An Olm!!", 
            "Woah, an Olm!", 
            "This ain't no Axolotl..", 
            "It looks like a recorder"
        }, 
        SparkleColor = Color3.fromRGB(255, 178, 178), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        ViewportSizeOffset = 2, 
        From = "Terrapin"
    }, 
    ["Sea Turtle"] = {
        WeightPool = {
            700, 
            1500
        }, 
        Chance = 0.005, 
        Rarity = "Mythical", 
        Resilience = 10, 
        ProgressEfficiency = 0.9, 
        Description = "The Sea Turtle is a graceful marine creature with a streamlined shell and paddle-like flippers, found gliding peacefully in warm coastal waters. Known for their calm demeanour and protected status, Sea Turtles are a rare and beautiful sight that often symbolizes good fortune.", 
        Hint = "Caught near Terrapin Island during the day.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 2000, 
        XP = 1000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "A TURTLEEE!", 
            "WOAH.. A TURTLE!", 
            "I like turtles :3", 
            "I caught a Sea Turtle!"
        }, 
        SparkleColor = Color3.fromRGB(160, 255, 83), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Terrapin"
    }, 
    Spiderfish = {
        WeightPool = {
            3, 
            10
        }, 
        Chance = 90, 
        Rarity = "Common", 
        Resilience = 90, 
        Description = "The Spiderfish is a rare void fish, caught only in Vertigos calm waters. They are schooling fish and are a common prey of Vertigos vicious predators.", 
        Hint = "Found commonly in Vertigo.", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 30, 
        XP = 20, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "I caught a Spiderfish!", 
            "Ouu! A Spiderfish!", 
            "A Spiderfish!"
        }, 
        SparkleColor = Color3.fromRGB(53, 60, 79), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Vertigo"
    }, 
    ["Night Shrimp"] = {
        WeightPool = {
            1, 
            2
        }, 
        Chance = 45, 
        Rarity = "Common", 
        Resilience = 200, 
        Description = "Night Shrimp are small, versatile crustaceans that can be found in an abundance in Vertigo's calm water. night Shrimp are predominantly diurnal, making day fishing the most effective time.", 
        Hint = "Caught with crab cages in Vertigo.", 
        FavouriteBait = "None", 
        FavouriteTime = "Day", 
        Price = 55, 
        XP = 35, 
        Seasons = {
            "Summer", 
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Night Shrimp!", 
            "Woah! A Night Shrimp", 
            "Awesome!", 
            "A Night Shrimp!", 
            "Ou! A Night Shrimpy!"
        }, 
        SparkleColor = Color3.fromRGB(49, 51, 74), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        From = "Vertigo"
    }, 
    ["Twilight Eel"] = {
        WeightPool = {
            100, 
            200
        }, 
        Chance = 70, 
        Rarity = "Uncommon", 
        Resilience = 40, 
        Description = "The Twilight Eel, whilst resembling a giant tadpole, is an Eel. Twilight Eels are extremely slimy, and use the bulb on their head to attract prey.", 
        Hint = "Found in Vertigo's Dip.", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 90, 
        XP = 100, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, a Twilight Eel!", 
            "I caught an Eel!", 
            "It looks like a tadpole!"
        }, 
        SparkleColor = Color3.fromRGB(128, 255, 121), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Vertigo"
    }, 
    ["Fangborn Gar"] = {
        WeightPool = {
            170, 
            380
        }, 
        Chance = 50, 
        Rarity = "Unusual", 
        Resilience = 30, 
        Description = "The Fangborn Gar is a vicious Voidwater fish that is completely blind. They roam the waters aimlessly and use a sense of smell to track food in Vertigo Dip.", 
        Hint = "Found in Vertigo's cave water.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = nil, 
        Price = 170, 
        XP = 100, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "A Gar!", 
            "I caught a Fangborn Gar!", 
            "Woah! A Fangborn Gar!", 
            "Oh my Gar!"
        }, 
        SparkleColor = Color3.fromRGB(32, 26, 48), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Vertigo"
    }, 
    Abyssacuda = {
        WeightPool = {
            55, 
            110
        }, 
        Chance = 20, 
        Rarity = "Rare", 
        Resilience = 10, 
        Description = "Abyssacudas are large predatory fish, known for their fearsome appearance and ferocious behaviour. They are adept swimmers, and are a top predator for the Twilight Eel. Abyssacudas are related to the Barracuda, however their cause for being primarily innate to Vertigo is unknown.", 
        Hint = "Found in Vertigos calm waters.", 
        FavouriteBait = "Minnow", 
        FavouriteTime = nil, 
        Price = 400, 
        XP = 90, 
        Seasons = {
            "Spring", 
            "Summer"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah, a n Abyssacuda!", 
            "I caught an Abyssacuda!", 
            "An Abyssacuda!!", 
            "Abyssacudaaaaa!!"
        }, 
        SparkleColor = Color3.fromRGB(87, 77, 116), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Vertigo"
    }, 
    ["Voidfin Mahi"] = {
        WeightPool = {
            75, 
            155
        }, 
        Chance = 10, 
        Rarity = "Rare", 
        Resilience = 10, 
        Description = "The Voidfin Mahi are extremely fast and sensitive fish. They can sense a heartbeat from hundreds of miles, and are capable of swimming through some solid bio-matters, such as wood.", 
        Hint = "Found in Vertigo.", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = nil, 
        Price = 450, 
        XP = 400, 
        Seasons = {
            "Spring"
        }, 
        Weather = {
            "Clear", 
            "Windy"
        }, 
        Quips = {
            "I caught a Voidfin Mahi!", 
            "Woah, a Voidfin Mahi!!", 
            "It's a Voidfin Mahi!"
        }, 
        SparkleColor = Color3.fromRGB(83, 67, 106), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        From = "Vertigo"
    }, 
    ["Rubber Ducky"] = {
        WeightPool = {
            1, 
            7
        }, 
        Chance = 0.01, 
        Rarity = "Legendary", 
        Resilience = 100, 
        ProgressEfficiency = 0.3, 
        Description = "A simple, squeezable, rubber duck! It may have been lost in one of the deepest parts of our discovered world... But, it's in great condition!", 
        Hint = "???", 
        FavouriteBait = "None", 
        FavouriteTime = nil, 
        Price = 900, 
        XP = 800, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Rain"
        }, 
        Quips = {
            "A.. Rubber Duck..?", 
            "Woah!.. A Ducky??", 
            "Awesome!!!!!!!", 
            "Did someone lose this?", 
            "How did this get down here..?"
        }, 
        SparkleColor = Color3.fromRGB(255, 234, 115), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        From = "Vertigo"
    }, 
    Isonade = {
        WeightPool = {
            6000, 
            13000
        }, 
        Chance = 0.1, 
        Rarity = "Mythical", 
        Resilience = 8, 
        ProgressEfficiency = 0.5, 
        Description = "The Isonade is a sinister creature that is assumed extinct. They are seeming to be a dream that is possible to be caught and captured. They only circle near Strange Whirlpools, can they even sometimes can be the cause for one.", 
        Hint = "Can be found when fishing in a strange whirlpool.", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = nil, 
        Price = 8000, 
        XP = 1200, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "WOAH!! I CAUGHT AN ISONADE!", 
            "AN ISONADE??", 
            "HOLY.. AN ISONADE??", 
            "I CAN'T FEEL MY SPINE!!", 
            "THESE EXIST?"
        }, 
        SparkleColor = Color3.fromRGB(47, 29, 106), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        From = "Vertigo"
    }, 
    Ghoulfish = {
        WeightPool = {
            45, 
            120
        }, 
        Chance = 0.1, 
        Rarity = "Limited", 
        Resilience = 30, 
        ProgressEfficiency = 0.9, 
        Description = "The Ghoulfish is known for its eerie appearance. They only appear during FischFright season, and are a scary bite to have on the end of your rod.", 
        Hint = "Only can be caught during FischFright.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 1000, 
        XP = 600, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "A Ghoulfish!", 
            "I caught a Ghoulfish!", 
            "Woah! A Ghoulfish!", 
            "Ouu! A Ghoulfish!", 
            "what? there's nothing there..", 
            "\240\159\145\187\240\159\145\187\240\159\145\187"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        FromLimited = "FischFright"
    }, 
    Lurkerfish = {
        WeightPool = {
            5, 
            20
        }, 
        Chance = 0.01, 
        Rarity = "Limited", 
        Resilience = 20, 
        ProgressEfficiency = 0.9, 
        Description = "The Lurkerfish is an interesting breed of the Anglerfish that is only visible during FischFright. It is said this fish gains its visible body from the though of FischFight, and during the rest of the year, the Lurkerfish is completely invisible to the untrained eye.", 
        Hint = "Only can be caught during FischFright.", 
        FavouriteBait = "Squid", 
        FavouriteTime = nil, 
        Price = 1500, 
        XP = 800, 
        Seasons = {
            "Winter", 
            "Autumn"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "Woah, a Lurkerfish!", 
            "No way! A Lurkerfish!", 
            "I caught a Lurkerfish!", 
            "I'm lurking..."
        }, 
        SparkleColor = Color3.fromRGB(140, 255, 176), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        FromLimited = "FischFright"
    }, 
    ["Candy Fish"] = {
        WeightPool = {
            5, 
            10
        }, 
        Chance = 10, 
        Rarity = "Limited", 
        Resilience = 50, 
        Description = "The Candy Fisch is a vibrant, bright coloured fish, formed from glucose and carbon. Known for their playful nature, and sweet gummy texture. Only can be caught during FischFright.", 
        Hint = "Only can be caught during FischFright.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 400, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Woah, a Candy Fisch!", 
            "No way! A Candy Fisch!", 
            "I caught a Candy Fisch!"
        }, 
        SparkleColor = Color3.fromRGB(255, 51, 51), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        FromLimited = "FischFright"
    }, 
    Zombiefish = {
        WeightPool = {
            15, 
            30
        }, 
        Chance = 10, 
        Rarity = "Limited", 
        Resilience = 50, 
        Description = "Once a lifeless fish drifting to the surface, the Zombiefish was struck by lightning and brought back to life. Now reanimated, it prowls the waters during FischFright, haunting the tides with its undead presence.", 
        Hint = "Only can be caught during FischFright.", 
        FavouriteBait = "Flakes", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 400, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Woah, a Zombiefish!", 
            "No way! A Zombiefish!", 
            "I caught a Zombiefish!", 
            "Rahh! I'm gonna eat your brains!"
        }, 
        SparkleColor = Color3.fromRGB(255, 51, 51), 
        HoldAnimation = l_fish_0:WaitForChild("small"), 
        FromLimited = "FischFright"
    }, 
    Skelefish = {
        WeightPool = {
            5, 
            10
        }, 
        Chance = 10, 
        Rarity = "Limited", 
        Resilience = 50, 
        Description = "The Skelefish is a literal fish skeleton, eerily animated as if it still had flesh. Its bony structure drifts through the water, with jagged, rib-like bones and a hollow skull that stares blankly ahead. Only can be caught during FischFright.", 
        Hint = "Only can be caught during FischFright.", 
        FavouriteBait = "Fish Head", 
        FavouriteTime = nil, 
        Price = 200, 
        XP = 400, 
        Seasons = {
            "Winter"
        }, 
        Weather = {
            "Clear"
        }, 
        Quips = {
            "Woah, a Skelefish!", 
            "No way! A Skelefish!", 
            "I caught a Skelefish!"
        }, 
        SparkleColor = Color3.fromRGB(255, 255, 255), 
        HoldAnimation = l_fish_0:WaitForChild("tiny"), 
        FromLimited = "FischFright"
    }, 
    Nessie = {
        WeightPool = {
            20000, 
            40000
        }, 
        Chance = 0.01, 
        Rarity = "Limited", 
        Resilience = 5, 
        ProgressEfficiency = 0.2, 
        Description = "Nessie is thought to be a complete myth. Little did these anglers know, you found the impossible catch... Nessie... Only obtainable during FischFright ", 
        Hint = "Only obtainable during FischFright", 
        FavouriteBait = "Truffle Worm", 
        FavouriteTime = "Night", 
        Price = 6500, 
        XP = 3000, 
        Seasons = {
            "None"
        }, 
        Weather = {
            "Foggy"
        }, 
        Quips = {
            "WOAH, NESSIE!?!", 
            "MY BACCKK", 
            "I CAN'T BELIEVE IT! NESSIE!", 
            "I DIDN'T THINK IT WAS REAL!!"
        }, 
        SparkleColor = Color3.fromRGB(129, 255, 181), 
        HoldAnimation = l_fish_0:WaitForChild("heavy"), 
        FromLimited = "FischFright"
    }, 
    Turkey = {
        WeightPool = {
            80, 
            300
        }, 
        Chance = 0, 
        Rarity = "Limited", 
        Resilience = 20, 
        ProgressEfficiency = 0.35, 
        Description = "Turkeys are large and heavy birds with a uniquely-shaped tail consisting of many feathers that line up to create a circular pattern. However, the poor Turkey is the desired choice of food for many fischers for Fischgiving dinner.", 
        Hint = "Only obtainable during Fischgiving", 
        FavouriteBait = "Insect", 
        FavouriteTime = nil, 
        Price = 4000, 
        XP = 1700, 
        Seasons = {
            "Autumn"
        }, 
        Weather = {
            "None"
        }, 
        Quips = {
            "Woah! a Turkey!", 
            "A Turkey!", 
            "Gobble Gobble!", 
            "Woah, A Turkey!"
        }, 
        SparkleColor = Color3.fromRGB(208, 104, 135), 
        HoldAnimation = l_fish_0:WaitForChild("basic"), 
        FromLimited = "Fischgiving"
    }, 
    Rarities = {
        [1] = "Trash", 
        [2] = "Common", 
        [3] = "Uncommon", 
        [4] = "Unusual", 
        [5] = "Rare", 
        [6] = "Legendary", 
        [7] = "Mythical", 
        [8] = "Divine", 
        [9] = "Exotic", 
        [10] = "Relic", 
        [11] = "Fragment", 
        [12] = "Gemstone", 
        [13] = "Limited"
    }, 
    RarityColours = {
        Trash = Color3.fromRGB(145, 145, 145), 
        Common = Color3.fromRGB(142, 187, 191), 
        Uncommon = Color3.fromRGB(161, 255, 169), 
        Unusual = Color3.fromRGB(192, 135, 198), 
        Rare = Color3.fromRGB(119, 108, 181), 
        Legendary = Color3.fromRGB(240, 181, 109), 
        Mythical = Color3.fromRGB(255, 62, 120), 
        Exotic = Color3.fromRGB(255, 255, 255), 
        Limited = Color3.fromRGB(54, 73, 159), 
        Divine = Color3.fromRGB(202, 198, 255), 
        Relic = Color3.fromRGB(120, 255, 183), 
        Fragment = Color3.fromRGB(255, 63, 5), 
        Gemstone = Color3.fromRGB(172, 57, 255)
    }, 
    ToInteger = function(_, v3) --[[ Line: 5429 ]] --[[ Name: ToInteger ]]
        return math.floor(v3.r * 255) * 65536 + math.floor(v3.g * 255) * 256 + math.floor(v3.b * 255)
    end
}
v4.ToHex = function(_, v6) --[[ Line: 5433 ]] --[[ Name: ToHex ]]
    local v7 = v4:ToInteger(v6)
    local v8 = ""
    local v9 = {
        "A", 
        "B", 
        "C", 
        "D", 
        "E", 
        "F"
    }
    repeat
        local v10 = v7 % 16
        local v11 = tostring(v10)
        if v10 >= 10 then
            v11 = v9[1 + v10 - 10]
        end
        v7 = math.floor(v7 / 16)
        v8 = v8 .. v11
    until v7 <= 0
    return "#" .. string.reverse(v8)
end
return v4
end)()

local waterWalkPart = Instance.new("Part", workspace)
waterWalkPart.Size = Vector3.new(10, 1, 10)
waterWalkPart.Transparency = 1
waterWalkPart.Anchored = true
waterWalkPart.CanTouch = false

local activeEvent = "None"
local activeEventChanged = Signal.new()

local AllRods = {}
for i,v in ReplicatedStorage.resources.items.rods:GetChildren() do
    table.insert(AllRods, v.Name)
end

local AllNPCs = {}
for i,v in workspace.world.npcs:GetChildren() do
    table.insert(AllNPCs, v.Name)
end

local AllItems = {} 
for i,v in workspace.world.interactables:GetChildren() do 
    if not string.find(v.Name, 'Rod') then 
        table.insert(AllItems, v.Name)
    end 
end 

local allSpots = {"Merlin", "MushGrove", "TheDepthsEntrance", "Deep", "Trident", "Elf", "Spike", "Ancient", "Santa", "Mod", "Statue", "Altar", "SunStone", "RosLit", "Swamp", "DeepShop", "DepthsMazeEnd", "TheDepths", "SnowCap", "Brine", "Enchant", "Executive", "MooseWood", "Arch", "Wilson", "DrFin", "Forsaken", "TheDepthsObby", "Christmas", "Workshop", "AncientArchivesEntrance", "Crafting", "Terrapin", "Desolate", "MirrorRoom", "LostIslandCave", "Volcano", "Archive", "Vertigo", "AncientArchives", "Uncharted", "Winter", "TheDepthsMazeExit", "Snow", "Keepers"}

local allAreas = {}
for _, fishingZone in fishingZones:GetChildren() do
    if not table.find(allAreas, fishingZone.Name) then
        table.insert(allAreas, fishingZone.Name)
    end
end

local customPositions = {
    ["Waterfall"] = CFrame.new(5813.45458984375, 135.301513671875, 411.3107604980469) * CFrame.Angles(-5.454796223602898e-07, -46.01728820800781, -9.819604684935257e-08),
    ["The Depths"] = CFrame.new(853.1495361328125, -740.3659057617188, 1334.452880859375) * CFrame.Angles(-0.00000184896646260313, 124.9924087524414, -0.0000034659037737583276)
}

local AllWaypoints = {}
for i,v in workspace.world.spawns:GetChildren() do
    if v:FindFirstChild('spawn') then
        table.insert(AllWaypoints, v.Name)
    end
end

local AllBaits = {}
for i,v in baitLibrary do
    table.insert(AllBaits, i)
end

local AllLocations = {
	["Moosewood"] = {
		["Moosewood"] = Vector3.new(388, 134, 233),
		["Moosewood Village"] = Vector3.new(469, 151, 253),
	},
	["Forsaken Shores"] = {
		Default = "Forsaken Shores",
		["Forsaken Shores"] = Vector3.new(-2493, 133, 1560),
	},
	["Roslit Bay"] = {
		Default = "Roslit Hamlet",
		["Roslit Hamlet"] = Vector3.new(-1472, 134, 712),
		["Roslit Pond"] = Vector3.new(-1786, 148, 640),
		["Roslit Volcano"] = Vector3.new(-1980, 160, 259),
	},
    ["Sunstone Island"] = {
        ['Sunstone Island'] = Vector3.new(-926.5847778320312, 131.07882690429688, -1106.7581787109375)
    },
    ['Desolate Pocket'] = Vector3.new(-2490.9609375, 133.25, 1556.3577880859375),

}

local bestEventBaits = {
    ['Megalodon'] = {
        'Shark Head',
        'Deep Coral',
        'Coral',
        'Seaweed'
    },
    ['Serpent'] = {
        'Truffle Worm',
        'Shark Head',
        'Magnet',
    },
    ["Whale Shark"] = {
        "Shrimp",
        "Shark Head", -- idk if this is the 2nd best
    },
    ['Great White Shark'] = {
        'Fish Head',
        'Magnet',
        'Garbage'
    }
}

local function StreamMapAsync(position)
	local t = task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, position, 20)
	repeat task.wait() until coroutine.status(t) == "dead"
end

local function Teleport(position)
	LocalPlayer.Character:PivotTo(CFrame.new(position) * CFrame.Angles(LocalPlayer.Character:GetPivot():ToOrientation()))
end

local function TeleportCFrame(cframe)
	LocalPlayer.Character:PivotTo(cframe)
end

local function ToNumber(str)
    str = str:gsub(",", ""):gsub("%s+", "")
    return tonumber(str)
end

local function FormatNumber(n)
    local s = tostring(math.round(n))
    local pattern = "^(-?%d+)(%d%d%d)"
    
    while string.find(s, pattern) do
        s = string.gsub(s, pattern, "%1,%2")
    end
    
    return s
end

local function GetNPCs()
	AllNPCs = {}
	for _, npc in workspace.world.npcs:GetChildren() do
		table.insert(AllNPCs, npc.Name)
	end
	return AllNPCs
end

local function GetItems() 
    AllItems = {} 
    for i,v in workspace.world.interactables:GetChildren() do 
        if not string.find(v.Name, 'Rod') then 
            table.insert(AllItems, v.Name)
        end 
    end 
end 

local function FindNPC(name, streamingPositions)
	for _, npc in workspace.world.npcs:GetChildren() do
		if npc.Name:find(name) then
			return npc
		end
	end

    if streamingPositions then
        for _, pos in streamingPositions do
            StreamMapAsync(pos)
            local npc = FindNPC(name)
            if npc then return npc end
        end
    end
end

local function GetMerchant()
	local merchant = nil
	for _, npc in workspace.world.npcs:GetChildren() do
		if npc.Name:find("Merchant") and npc:FindFirstChild("sellall", true) then
			merchant = npc
			break
		end
	end

	if not merchant then
		StreamMapAsync(Vector3.new(952, -710, 1262))
		return GetMerchant()
	end

	return merchant
end

local function GetAppraiser() 
    local appraiser = workspace.world.npcs:FindFirstChild('Appraiser')
    if not appraiser then 
        StreamMapAsync(Vector3.new(447, 150, 208))
        return GetAppraiser()
    end 
    return appraiser
end 

local function HasItem(itemName : string)
    return LocalPlayer:WaitForChild("Backpack"):FindFirstChild(itemName)
end

local function HasBait(baitName : string)
    local baitObj = playerStats.Stats.bait:FindFirstChild("bait_" .. baitName)
	return baitObj and baitObj.Value > 0
end 

local function HasFishToSell()
    local has = false

    local whitelistedRarities = {"common", "uncommon", "unusual", "rare"} 
    for _, option in playerStatSettings:GetChildren() do 
        if string.find(option.Name, 'willautosell') and option.Value == true then 
            local rarityName = option.Name:split('_')[2]
            print(rarityName)
            if rarityName == 'event' then 
                table.insert(whitelistedRarities, 'limited')
            else 
                table.insert(whitelistedRarities, rarityName)
            end 
        end 
    end 

    for _, item in playerStats.Inventory:GetChildren() do 
        local trueName = item.Name:sub(1, #item.Name-9)
        if fishLibrary[trueName] ~= nil then 
            local fishObj = fishLibrary[trueName]

            if table.find(whitelistedRarities, fishObj.Rarity:lower()) then 
                has = true 
                -- print(has)
                break
            end 
        end 
    end 
    
    return has
end

local modValues = {}
local function setBoat(tbl, property, val)
	for i,v in tbl do
		if typeof(v) == 'table' and v[property] then
			v[property] = val
			modValues[property] = val
		end
	end
end

local build = "Public Build" if not LPH_OBFUSCATED then build = "Development Build" end

local base: UIBase = UIBase.new():setLabel("Kiciahook | Fisch | " .. build) do
	local tabList: UITabList = base:newTabList()

    local farming: UITabList = tabList:newTab("Farming"):newTabList() do
        local fishing: UISectionHolder = farming:newTab("Fishing"):intoSections()
        do
            local autoCast: UISection = fishing:newSection("left", "Auto Cast")
            do
                autoCast:newToggle("farming/fishing/auto_cast"):setLabel("Auto Cast")
                autoCast:newToggle("farming/fishing/auto_equip_rod"):setLabel("Auto Equip Rod")

                autoCast:newLabel("castTypeLabel"):setLabel("Cast Type")
                autoCast:newDropdown("farming/auto_cast/type", false, {"Legit [SOON]", "Semi-Legit", "Blatant"}):set("Legit")

                autoCast:newLabel("castAccuracyLabel"):setLabel("Cast Accuracy")
                autoCast:newSlider("farming/auto_cast/accuracy/perfect", 10, 100, 1):set(100):setLabel("Perfect Cast Chance")

                autoCast:newSlider("farming/auto_cast/delay", 0, 5, 10):set(0):setLabel("Cast Delay")
            end

            local autoBait: UISection = fishing:newSection("left", "Auto Bait")
            do
                autoBait:newToggle("farming/auto_bait"):setLabel("Auto Bait")

                autoBait:newToggle("farming/auto_bait/use_available"):setLabel("Use Available")
                
                autoBait:newToggle("farming/auto_bait/best_bait_for_events"):setLabel("Pick Best Bait For Events")
                autoBait:newToggle("farming/auto_bait/best_bait_for_area"):setLabel("Pick Best Bait For Area")

                autoBait:newDropdown("farming/auto_bait/type", false, AllBaits)
            end

            local autoShake: UISection = fishing:newSection("right", "Auto Shake")
            do
                autoShake:newToggle("farming/auto_shake"):setLabel("Auto Shake")

                autoShake:newLabel("autoShakeTypeLabel"):setLabel("Auto Shake Type")
                autoShake:newDropdown("farming/auto_shake/type", false, {"Click", "UI Navigation"}):set("UI Navigation")
            end

            local autoReel: UISection = fishing:newSection("right", "Auto Reel")
            do
                autoReel:newToggle("farming/auto_reel"):setLabel("Auto Reel")

                autoReel:newLabel("autoReelTypeLabel"):setLabel("Auto Reel Type")
                autoReel:newDropdown("farming/auto_reel/type", false, {"Legit [SOON]", "Blatant"}):set("Blatant")
            end
        end

        local misc: UISectionHolder = farming:newTab("Events, Areas, Other"):intoSections()
        do
            local events: UISection = misc:newSection("left", "Events")
            do
                events:newToggle("farming/events/auto_megalodon"):setLabel("Auto Megalodon")
                events:newToggle("farming/events/auto_whale_shark"):setLabel("Auto Whale Shark")
                events:newToggle("farming/events/auto_great_white_shark"):setLabel("Auto Great White Shark")
                events:newToggle("farming/events/auto_depth_serpent"):setLabel("Auto Depth Serpent")
                events:newToggle("farming/events/auto_meteor"):setLabel("Auto Meteor")
            end

            local areas: UISection = misc:newSection("right", "Areas")
            do
                areas:newLabel("allAreasLabel"):setLabel("All Areas")

                areas:newDropdown("farming/areas/all", false, {"None", unpack(allAreas)}, function()
                    allAreas = {}
                    for _, fishingZone in fishingZones:GetChildren() do
                        if not table.find(allAreas, fishingZone.Name) then
                            table.insert(allAreas, fishingZone.Name)
                        end
                    end
                    return {"None", unpack(allAreas)}
                end, true)
                areas:newToggle("farming/areas/farm_in_area"):setLabel("Farm In Area")

                local customAreasPath = HOME_DIR .. "/custom_areas.json"

                local function CreateFile()
                    local toEncodeAreas = table.clone(customPositions)
                    for i, v in toEncodeAreas do
                        toEncodeAreas[i] = {v:components()}
                    end
                    writefile(customAreasPath, HttpService:JSONEncode(toEncodeAreas))
                end

                local function ParseFile()
                    local toDecodeAreas = HttpService:JSONDecode(readfile(customAreasPath))
                    for i, v in toDecodeAreas do
                        toDecodeAreas[i] = CFrame.new(unpack(v))
                    end
                    customPositions = toDecodeAreas
                    warn("MEOWMEOWMEOWMEOWMEOWMEOWMEOW")
                end

                local function AddCustomPosition(name, cframe)
                    customPositions[name] = cframe
                    CreateFile()
                end

                local function DeleteCustomPosition(name)
                    customPositions[name] = nil
                    CreateFile()
                end

                local function GetCustomPositionsForDropdown()
                    local customPositionsArray = {}
                    for name in customPositions do
                        table.insert(customPositionsArray, name)
                    end
                    return {"None", unpack(customPositionsArray)}
                end

                if not isfile(customAreasPath) then
                    CreateFile()
                end

                local status, success = pcall(ParseFile)
                if not status then
                    CreateFile()
                    status, success = pcall(ParseFile)
                    if not status then LocalPlayer:Kick("Error: " .. success) return end
                end

                areas:newLabel("customPositionsLabel"):setLabel("Custom Positions")
                do
                    areas:newDropdown("farming/areas/custom_position", false, GetCustomPositionsForDropdown(), function()
                        pcall(ParseFile)
                        return GetCustomPositionsForDropdown()
                    end, true)
                    -- Farm in custom pos
                    areas:newToggle("farming/areas/farm_in_custom_pos"):setLabel("Farm In Custom Position")

                    -- Add your own custom pos
                    areas:newLabel("addYourOwnPosLabel"):setLabel("Add Your Own Custom Position")

                    local areaName = areas:newTextBox("farming/areas/custom_pos_name"):setLabel("Position Name")

                    areas:newButton("farming/areas/add_custom_pos"):setLabel("Add Custom Position").changed:Connect(function()
                        if not rootPart then return end
                        AddCustomPosition(areaName.value, rootPart.CFrame)
                        customPositionsDropdown:setOptions(GetCustomPositionsForDropdown())
                    end)

                    areas:newButton("farming/areas/delete_custom_pos"):setLabel("Delete Custom Position").changed:Connect(function()
                        DeleteCustomPosition(areaName.value)
                        local old = customPositionsDropdown.value
                        customPositionsDropdown:setOptions(GetCustomPositionsForDropdown())
                        customPositionsDropdown:set(old)
                    end)
                end
            end

            local other: UISection = misc:newSection("left", "Other")
            do
                other:newToggle("farming/other/freeze_plr"):setLabel("Freeze Player")
            end
        end
    end

    local world: UISectionHolder = tabList:newTab("World"):intoSections() do
		local waypoints: UISection = world:newSection("left", "Waypoints")
        waypoints:newDropdown("world/waypoints/selection", false, AllWaypoints, nil, true)
        waypoints:newButton('world/waypoints/teleport'):setLabel('Teleport').changed:Connect(function()
            local selectedWaypoint = base.features['world/waypoints/selection'].value
            local waypointPart = workspace.world.spawns[selectedWaypoint]:FindFirstChild('spawn')
            rootPart.CFrame = waypointPart.CFrame
        end)

        local npc = world:newSection("left", "NPC")
        npc:newDropdown("world/npc/selection", false, AllNPCs, function()
			GetNPCs()
			return AllNPCs
		end, true)
        npc:newButton("world/npc/teleport"):setLabel("Teleport").changed:Connect(function()
            local selectedNpc = base.features["world/npc/selection"].value
            if workspace.world.npcs:FindFirstChild(selectedNpc) then
                local npcObject = workspace.world.npcs[selectedNpc]
                if selectedNpc == "mirror Area" then
                    Teleport(npcObject["Magic Mirror"].Main.CFrame.Position + Vector3.new(0, 5, -1))
                else
                    Teleport(npcObject.HumanoidRootPart.CFrame + Vector3.new(0, 5, -1))
                end
            end
        end)

        local items: UISection = world:newSection('right', 'Items') 
        items:newDropdown('world/items/selection', false, AllItems, function()
            GetItems() 
            return AllItems 
        end, true)
        items:newButton('world/items/teleport'):setLabel('Teleport').changed:Connect(function()
            local selectedItem = base.features['world/items/selection'].value 
            if workspace.world.interactables:FindFirstChild(selectedItem) then 
                local itemObject = workspace.world.interactables[selectedItem]
                Teleport(itemObject:GetPivot().Position + Vector3.new(0, 5, 0))
            end 
        end)

        local spots: UISection = world:newSection('right', 'Spots') 
        spots:newDropdown('world/spots/selection', false, allSpots, nil, true)
        spots:newButton('world/spots/teleport'):setLabel('Teleport').changed:Connect(function()
            local selectedSpot = base.features['world/spots/selection'].value 
            if workspace.world.spawns.TpSpots:FindFirstChild(selectedSpot:lower()) then 
                local spotObject = workspace.world.spawns.TpSpots[selectedSpot:lower()]
                Teleport(spotObject.Position + Vector3.new(0, 5, 0))
            end 
        end)
    end

	local market: UISectionHolder = tabList:newTab("Market"):intoSections() do
		local function AttemptPurchase(name, type)
			ReplicatedStorage.events.purchase:FireServer(name, type, nil, 1)
		end

		--local fish: UISection = market:newSection("left", "Fish")
		local items: UISection = market:newSection("left", "Items")
		do
			local allItems = {}
			for itemName in itemsLibrary.Items do
				if not itemName:find("Totem") then
					table.insert(allItems, itemName)
				end
			end

			local selectedItem = items:newDropdown("market/items/selection", false, allItems, nil, true)
			local amountTextbox = items:newTextBox("market/items/amount"):setLabel("Amount (e.g. 5)")
            items:newButton("market/items/purchase"):setLabel("Purchase").changed:Connect(function()
                local amount = ToNumber(amountTextbox.value)
                if amount and coins.Value >= itemsLibrary.Items[selectedItem.value].Price * amount then
				    ReplicatedStorage.events.purchase:FireServer(selectedItem.value, "Item", nil, amount)
                end
			end)
		end

        local appraise: UISection = market:newSection('right', 'Appraise')
        do
            appraise:newLabel('autoAppraiseType'):setLabel('Auto Appraise By')
            -- TODO: add , 'Exotic', 'Event'
            local appraiseType = appraise:newDropdown('market/appraise/appraise_type', false, {'Equipped Fish'}, nil, true)

            appraise:newLabel("appraiseWeightOver"):setLabel("Appraise If Weight Over (kg)")
            appraise:newTextBox('market/appraise/min_weight'):setLabel('Min Weight (e.g. 10,000)')

            appraise:newLabel("appraiseCoinsOver"):setLabel("Buy If Coins Over (C$)")
            appraise:newTextBox('market/appraise/min_cash'):setLabel('Min Cash (e.g. 100,000)')

            appraise:newToggle('market/appraise/auto_appraise'):setLabel('Auto Appraise')
        end 

		local fish: UISection = market:newSection("right", "Fish")
		do
            local allFish = {}
			for itemName in fishLibrary do
				table.insert(allFish, itemName)
			end

			local selectedFish = fish:newDropdown("market/fish/selection", false, allFish, nil, true)
			local amountTextbox = fish:newTextBox("market/fish/amount"):setLabel("Amount (e.g. 5)")
            fish:newButton("market/fish/purchase"):setLabel("Purchase").changed:Connect(function()
                local amount = ToNumber(amountTextbox.value)
                if amount and coins.Value >= fishLibrary[selectedFish.value].Price * amount then
				    ReplicatedStorage.events.purchase:FireServer(selectedFish.value, "Fish", nil, amount)
                end
			end)
		end

		local totems: UISection = market:newSection("left", "Totems")
		do
			local allTotems = {}
			for itemName in itemsLibrary.Items do
				if itemName:find("Totem") then
					table.insert(allTotems, itemName)
				end
			end

			local selectedTotem = totems:newDropdown("market/totems/selection", false, allTotems, nil, true)
			local amountTextbox = totems:newTextBox("market/totems/amount"):setLabel("Amount (e.g. 5)")
            totems:newButton("market/totems/purchase"):setLabel("Purchase").changed:Connect(function()
				local amount = ToNumber(amountTextbox.value)
                if amount and coins.Value >= itemsLibrary.Items[selectedTotem.value].Price * amount then
					ReplicatedStorage.events.purchase:FireServer(selectedTotem.value, "Item", nil, amount)
				end
			end)

			totems:newLabel("autoPurchaseTotems"):setLabel("Auto Purchase Totem(s)")
			totems:newDropdown("market/totems/multi_selection", true, allTotems, nil, true)
			totems:newLabel("coinsOverLabel"):setLabel("Buy If Coins Over (C$)")
			totems:newTextBox("market/totems/auto_purchase/min_cash"):setLabel("Min Cash (e.g. 100,000)")
			totems:newToggle("market/totems/auto_purchase"):setLabel("Auto Purchase")
		end

		local rods: UISection = market:newSection("right", "Rods")
		do
			local selectedRod = rods:newDropdown("market/rods/selection", false, AllRods, nil, true)
			rods:newButton("market/rods/purchase"):setLabel("Purchase").changed:Connect(function()
				ReplicatedStorage.events.purchase:FireServer(selectedRod.value, "Rod", nil, 1)
			end)
		end

        local baitCrates: UISection = market:newSection("right", "Bait Crates")
        do
            local selectedBait = baitCrates:newDropdown("market/bait_crates/selection", false, {"Bait Crate", "Quality Bait Crate"}, nil, true)
            local amountTextbox = baitCrates:newTextBox("market/bait_crates/amount"):setLabel("Amount (e.g. 5)")
            baitCrates:newButton("market/bait_crates/purchase"):setLabel("Purchase").changed:Connect(function()
				local amount = ToNumber(amountTextbox.value)
                if amount and coins.Value >= fishLibrary[selectedBait.value].Price * amount then
                    ReplicatedStorage.events.purchase:FireServer(selectedBait.value, "Fish", nil, amount)
                end
			end)
        end

		local inventory: UISection = market:newSection("right", "Inventory")
		do
			inventory:newToggle("market/inventory/auto_sell"):setLabel("Auto Sell All")
			inventory:newToggle("market/inventory/disable_sell_if_crates"):setLabel("Disable Sell All If Crates Are Found")
		end
	end

    local stats: UISectionHolder = tabList:newTab("Stats"):intoSections()
    do
        local gains: UISection = stats:newSection("left", "Gains")
        do
            gains:newLabel("stats/gains/coinsOverallLabel"):setLabel("Gained Coins:")
            gains:newLabel("stats/gains/coins_overall"):setLabel("C$ -"):setColor(Color3.fromRGB(255, 250, 179))

            gains:newLabel("stats/gains/coinsHrLabel"):setLabel("Estimated Coins Per Hour:")
            gains:newLabel("stats/gains/coins_per_hr"):setLabel("C$ -"):setColor(Color3.fromRGB(255, 250, 179))
        end
    end

	-- local teleports: UISectionHolder = tabList:newTab("Teleports"):intoSections() do
	-- 	local function createTeleports(section: string, flag: string, label: string, positions: table | string, streaming: table?)
	-- 		local options = {}
	-- 		for name in positions do
	-- 			table.insert(options, name)
	-- 		end

	-- 		section:newLabel(flag .. label):setLabel(label)
	-- 		local dropdown = section:newDropdown(flag, false, options, true)
	-- 		dropdown.changed:Connect(function(state)
	-- 			if type(positions[state]) == "string" and streaming and streaming[state] then
	-- 				for _, pos in streaming[state] do
	-- 					local t = task.spawn(LocalPlayer.RequestStreamAroundAsync, LocalPlayer, pos, 20)
	-- 					repeat task.wait() until coroutine.status(t) == "dead"
	-- 				end

	-- 				local currentDir = workspace
	-- 				for _, str in positions[state]:split("/") do
	-- 					currentDir = currentDir:FindFirstChild(str)
	-- 					if not currentDir then warn("Failed to teleport", positions[state]) break end
	-- 				end
	-- 				Teleport(currentDir.PrimaryPart.Position)
	-- 			else
	-- 				Teleport(positions[state])
	-- 				task.wait(0.1)
	-- 				dropdown:set(nil)
	-- 			end
	-- 		end)
	-- 	end



	-- 	-- local moosewood = teleports:newSection("left", "Moosewood Island")
	-- 	-- createTeleports(moosewood, "teleports/moosewood_island/areas", "Areas", {
	-- 	-- 	["Moosewood"] = Vector3.new(388.7363586425781, 135.47918701171875, 234.24765014648438),
	-- 	-- 	["Village"] = Vector3.new(481.679931640625, 152.16549682617188, 260.4496154785156),
	-- 	-- })
	-- 	-- -- moosewood:newDropdown("teleports/moosewood_island/areas")
	-- 	-- createTeleports(moosewood, "teleports/moosewood_island/npcs", "NPCs", {
	-- 	-- 	["Merchant"] = Vector3.new(465.28912353515625, 152.11111450195312, 230.16439819335938),
	-- 	-- 	["Appraiser"] = Vector3.new(447.3930969238281, 152.0202178955078, 206.82264709472656),
	-- 	-- 	["Phineas"] = Vector3.new(471.3871154785156, 152.16514587402344, 274.76666259765625),
	-- 	-- 	["Angler"] = Vector3.new(480.44964599609375, 151.97425842285156, 298.4384765625),
	-- 	-- 	["Inn Keeper"] = Vector3.new(490.44732666015625, 152.17405700683594, 233.70359802246094),
	-- 	-- 	["Lantern Keeper"] = "world/npcs/Latern Keeper",
	-- 	-- }, {
	-- 	-- 	["Lantern Keeper"] = {
	-- 	-- 		Vector3.new(658.445984, 163.5, 260.213989),
	-- 	-- 		Vector3.new(715.960022, 167.533005, 335.924988),
	-- 	-- 		Vector3.new(-1763.37598, 130.408997, 526.23999)
	-- 	-- 	}
	-- 	-- })

	-- 	-- createTeleports(moosewood, "teleports/moosewood_island/items", "Items", {
	-- 	-- 	["Basic Diving Gear"] = Vector3.new(371.8304443359375, 135.9309539794922, 248.09727478027344),
	-- 	-- 	["Fish Radar"] = Vector3.new(368.3010559082031, 138.47781372070312, 274.34820556640625),
	-- 	-- 	["Bait Crate"] = Vector3.new(386.8402099609375, 138.4658660888672, 335.2644348144531),
	-- 	-- 	["Crab Cage"] = Vector3.new(476.054443359375, 151.97467041015625, 233.9663543701172),
	-- 	-- })
	-- end

    local misc: UISectionHolder = tabList:newTab("Misc"):intoSections() do
		local passed = pcall(function()
			require(boats)
		end)

		local playerMods = misc:newSection("left", "Player Mods")
		do
			playerMods:newLabel("misc/player/click_teleport"):setLabel("Click Teleport"):newKeybind("misc/player/click_teleport/keybind", {"Tap"}):set({key = nil, mode = "Tap"}).activeChanged:Connect(function()
				local Root = LocalPlayer.Character.HumanoidRootPart
				local oriX, oriY, oriZ = Root.CFrame:ToOrientation()
				Root.CFrame = CFrame.new(LocalPlayer:GetMouse().Hit.Position) * CFrame.new(0, 2.5, 0) * CFrame.fromOrientation(oriX, oriY, oriZ)

			end)

			playerMods:newToggle("misc/player/infinite_oxygen"):setLabel("Infinite Oxygen").changed:Connect(function(t)
				-- local oxygen = character.client.oxygen
                -- oxygen.Enabled = not t
				-- if t then
				-- 	for _, v in LocalPlayer.Character.Head:GetChildren() do
				-- 		if v.Name == "ui" then
				-- 			v:Destroy()
				-- 		end
				-- 	end
				-- end
			end)

			playerMods:newToggle("misc/movement/flight"):setLabel("Enable Flight"):newKeybind("misc/movement/flight/bind", {"Always", "Toggle", "Hold", "Release"}):set({key = nil, mode = "Always"})
			playerMods:newSlider("misc/movement/flight/value", 0, 500, 1):setLabel("Flight Speed"):set(50)

			playerMods:newToggle("misc/movement/noclip"):setLabel("Noclip"):newKeybind("misc/movement/noclip/bind", {"Always", "Toggle", "Hold", "Release"}):set({key = nil, mode = "Always"})

			playerMods:newToggle("misc/player/walk_on_water"):setLabel("Walk On Water").changed:Connect(function(state)
                if not state then 
                    waterWalkPart.CFrame = CFrame.new(0,0,0)
                end 
            end)
            playerMods:newToggle("misc/player/disable_swimming"):setLabel("Disable Swimming").changed:Connect(function(state)
                if activeEvent == "None" then
                    character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, not state)
                end
            end)
		end

		if passed then -- check if executor supports require func
			local boatmods = misc:newSection("right", "Boat Mods")
			local boatmodule = require(boats)
			local oldBoats = {}
			local newBoats = {}

			for i,v in boatmodule.library do
				oldBoats[i] = v
			end

			boatmods:newToggle("misc/boat/enabled"):setLabel("Enabled").changed:Connect(function(state)
				if state then
					if newBoats["set"] then
						boatmodule.library = newBoats
					end
                    setBoat(boatmodule.library, "MaxSpeed", base.features["misc/boat/speed_amount"].value)
                    setBoat(boatmodule.library, "Accel", base.features['misc/boat/acceleration'].value)
                    setBoat(boatmodule.library, "Accel", base.features['misc/boat/turning_speed'].value)
				else
					newBoats = boatmodule.library
					newBoats["set"] = true
					boatmodule.library = oldBoats
				end
			end)

			local modsflag = base.features["misc/boat/enabled"]
			boatmods:newSlider("misc/boat/speed_amount", 10, 300, 1):setLabel("Speed"):set(150).changed:Connect(function(val)
				if modsflag.value then
					setBoat(boatmodule.library, "MaxSpeed", val)
				end
			end)
			boatmods:newSlider("misc/boat/acceleration", 0.5, 5, 10):setLabel("Acceleration"):set(2).changed:Connect(function(val)
				if modsflag.value then
					setBoat(boatmodule.library, "Accel", val)
				end
			end)
			boatmods:newSlider("misc/boat/turning_speed", 0.5, 5, 10):setLabel("Turn Speed"):set(2).changed:Connect(function(val)
				if modsflag.value then
					setBoat(boatmodule.library, "Turning Speed", val)
				end
			end)
		end

        -- Boat Stuff

        local function SpawnBoat(boatName)
            local Shipwright = FindNPC("Shipwright", {Vector3.new(360, 135, 258)})
            fireproximityprompt(Shipwright.dialogprompt)

            task.wait()

            pcall(function()
                ReplicatedStorage.packages.Net["RF/AppraiseAnywhere/HaveValidFish"]:InvokeServer()
                Shipwright.shipwright.giveUI:InvokeServer()
                task.wait()
                LocalPlayer.PlayerGui.hud.safezone.shipwright.ships.main.safezone.spawnattempt:FireServer(boatName)
            end)
        end

		local boat = misc:newSection("left", "Boat")
		do
			local selectedBoat = boat:newDropdown("misc/boat/selection", false, {}, function()
				local boatNames = {}
				for _, boat in playerStats.Boats:GetChildren() do
					table.insert(boatNames, boat.Name)
				end
				return boatNames
			end, true)

			boat:newButton("misc/boat/spawn_boat"):setLabel("Spawn Boat").changed:Connect(function()--require kotek :x: WDYM ❌
				SpawnBoat(selectedBoat.value)
			end)

			boat:newButton("misc/boat/spawn&bring"):setLabel("Spawn & Bring Boat").changed:Connect(function()
				local character = LocalPlayer.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart")
				if not rootPart then return end
                local humanoid = character:FindFirstChild("Humanoid")
                if not humanoid then return end
                if humanoid.Sit then
                    humanoid.Jump = true
                    humanoid.Sit = false
                    task.wait(0.25)
                end

                local oldCFrame = rootPart.CFrame

				SpawnBoat(selectedBoat.value)

                local boatModel
                local ownerSeat
				while task.wait() do
                    local activeBoats = workspace.active.boats:FindFirstChild(LocalPlayer.Name)
                    if not activeBoats then continue end

					boatModel = activeBoats:FindFirstChildOfClass("Model")
					if not boatModel then continue end

					ownerSeat = boatModel:FindFirstChild("owner")
					if not ownerSeat then continue end
					if ownerSeat.Occupant then break end
					
					Teleport(boatModel.PrimaryPart.Position + Vector3.new(0, 8, 0))
					rootPart.Velocity = Vector3.zero
					fireproximityprompt(ownerSeat.sitprompt)
				end
                boatModel:PivotTo(oldCFrame)
			end)
		end

        local troll = misc:newSection("right", "Troll")
        do
            local flingTask = nil
            local scriptableCameraTask = nil
            local flingDesync = nil
            local flingHeight = workspace.FallenPartsDestroyHeight

            local function GetPlayersToFling()
                local plrs = {} 
                for _, player in Players:GetPlayers() do 
                    if player == Players.LocalPlayer then continue end
                    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
                    if player.Character.Humanoid.Sit then continue end
                    table.insert(plrs, ("%s (%s)"):format(player.Name, player.DisplayName))
                end 
    
                return plrs
            end 

            local function setPos(boat, pos)
                boat.CFrame = CFrame.new(pos)
            end

            troll:newDropdown('misc/troll/player', false, GetPlayersToFling(), function()
                return GetPlayersToFling()
            end, true)

            troll:newButton('misc/troll/teleport'):setLabel('Teleport To Player').changed:Connect(function()
                if not rootPart then return end
                local targetPlayer = Players:FindFirstChild(base.features['misc/troll/player'].value:split(" ")[1])
                if not targetPlayer then return end
                local character = targetPlayer.Character
                if not character then return end

                Teleport(character:GetPivot().Position + Vector3.new(0, 3, 0))
            end)

            troll:newButton('misc/troll/troll'):setLabel('Kill Player (sometimes buggy)').changed:Connect(function()
                if scriptableCameraTask then task.cancel(scriptableCameraTask) scriptableCameraTask = nil end
                if flingTask then task.cancel(flingTask) flingTask = nil end
                if activeEvent ~= "None" then return end
                
                local targetPlayer = base.features['misc/troll/player'].value:split(" ")[1]
                local boat = base.features['misc/boat/selection'].value
                flingTask = task.spawn(function()
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then return end
                    local humanoid = character:FindFirstChild("Humanoid")
                    if not humanoid then return end
                    if humanoid.Sit then
                        humanoid.Jump = true
                        humanoid.Sit = false
                        task.wait(0.25)
                    end

                    local oldRootCFrame = rootPart.CFrame

                    scriptableCameraTask = task.spawn(function()
                        while true do
                            PlayerGui.hud.Enabled = false
                            CurrentCamera.CameraType = Enum.CameraType.Scriptable
                            task.wait()
                            CurrentCamera.CFrame = CFrame.new(0, 999999, 0)
                            -- RunService:Set3dRenderingEnabled(false)
                        end
                    end)

                    SpawnBoat(boat)
                    
                    local boatModel
                    local ownerSeat
                    local startTime = os.clock()
                    while task.wait() and os.clock() - startTime < 5 do
                        local activeBoats = workspace.active.boats:FindFirstChild(LocalPlayer.Name)
                        if not activeBoats then continue end

                        boatModel = activeBoats:FindFirstChildOfClass("Model")
                        if not boatModel then continue end

                        ownerSeat = boatModel:FindFirstChild("owner")
                        if not ownerSeat then continue end
                        if ownerSeat.Occupant then break end
                        
                        Teleport(boatModel.PrimaryPart.Position + Vector3.new(0, 8, 0))
                        rootPart.Velocity = Vector3.zero
                        fireproximityprompt(ownerSeat.sitprompt, 5, false)
                    end

                    if os.clock() - startTime >= 5 then
                        task.cancel(scriptableCameraTask)
                        return
                    end
                    
                    flingDesync = Desync.new(boatModel.PrimaryPart, "Velocity", Vector3.new(16384, 16384, 16384))
                    local v = Players:FindFirstChild(targetPlayer)
                    local oldPos = boatModel.PrimaryPart.CFrame
                    if v then 
                        pcall(function()
                            startTime = os.clock()
                            repeat 
                                task.wait() 
                                workspace.FallenPartsDestroyHeight = 0/0
                                local pos = v.Character.HumanoidRootPart.Position
                                if v.Character.Humanoid.Sit then
                                    pos -= Vector3.new(0, 2, 0)
                                end
                                setPos(boatModel.PrimaryPart, pos)
                            until v.Character.HumanoidRootPart.Velocity.Magnitude > 100 or os.clock() - startTime >= 5
                        end)
                    end

                    workspace.FallenPartsDestroyHeight = flingHeight 
                    flingDesync:Disconnect() 
                    boatModel.PrimaryPart.Velocity = Vector3.zero

                    if humanoid.Sit then
                        humanoid.Jump = true
                        humanoid.Sit = false
                        task.wait(0.25)
                    end

                    TeleportCFrame(oldRootCFrame)

                    task.cancel(scriptableCameraTask)
                    scriptableCameraTask = nil

                    CurrentCamera.CameraType = Enum.CameraType.Custom
                    CurrentCamera.CameraSubject = humanoid
                    PlayerGui.hud.Enabled = true
                    RunService:Set3dRenderingEnabled(true)
                    PlayerGui.hud.safezone.announcements.Visible = false
                    task.wait(4)
                    PlayerGui.hud.safezone.announcements.Visible = true
                end)
            end)
                
            troll:newButton('misc/troll/cancel'):setLabel('Cancel Kill').changed:Connect(function()
                if flingTask then 
                    task.cancel(flingTask)
                    flingTask = nil
                end 
            end)
        end

		local other = misc:newSection("right", "Other")
		do
			other:newToggle("misc/other/fish_radar"):setLabel("Fish Radar")
            other:newToggle("misc/other/auto_crate"):setLabel("Auto Open Crates")
            other:newToggle("misc/other/auto_claim_treasure_maps"):setLabel("Auto Claim Treasure Maps")
			--other:newToggle("misc/other/treasure_map_helper"):setLabel("Treasure Map Helper")
			other:newButton("misc/other/discover_all_locs"):setLabel("Discover All Locations").changed:Connect(function()
				local locations = {
					"The Depths",
					"Roslit Bay",
					"Ancient Isle",
					"Sunstone Island",
					"Roslit Volcano",
					"Desolate Deep",
					"Mushgrove Swamp",
					"Moosewood Island",
					"Keepers Altar",
					"Vertigo",
					"FischFright",
					"Terrapin Island",
					"Archeological Site",
					"Ancient Archives",
					"Snowcap Island",
					"Brine Pool",
					"Fischgiving",
					"Every",
					"Forsaken Shores",
					"Ocean",
				}

				for _, location in locations do
					ReplicatedStorage.events.discoverlocation:FireServer(location)
				end
			end)
		end

        local autoTotem = misc:newSection("left", "Auto Totem")
        do
            autoTotem:newToggle("misc/auto_totem/enabled"):setLabel("Enable Auto Totem")
            autoTotem:newDropdown("misc/auto_totem/totems", true, {"Aurora Totem", "Sundial Totem"})
        end
    end

	local settings: UISectionHolder = tabList:newTab("Settings"):intoSections() do
		local menu = settings:newSection("left", "Menu")
		if UserInputService.KeyboardEnabled then
			menu:newLabel("Keybind"):setLabel("Keybind"):newKeybind("settings/menu/keybind", { "Tap" }):set({key = Enum.KeyCode.RightShift, mode = "Tap"}).activeChanged:Connect(function()
				base:setVisible(not base.visible)
			end)
		end

		local server = settings:newSection("left", "Server")
        server:newButton("settings/server/reconnect"):setLabel("Reconnect").changed:Connect(function()
			-- otherwise data might not load in time
            game:GetService("Players").LocalPlayer:Kick()
			game:GetService("GuiService"):ClearError()
			task.wait(1)
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end)

		server:newButton("settings/server/copy_jobid"):setLabel("Copy JobId").changed:Connect(function()
            setclipboard(tostring(game.JobId))
        end)

        server:newButton("settings/server/copy_invite"):setLabel("Copy Invite").changed:Connect(function()
            setclipboard(("game:GetService(\"TeleportService\"):TeleportToPlaceInstance(%s, \"%s\")"):format(game.PlaceId, game.JobId))
        end)

        if not LPH_OBFUSCATED then
            local debug = settings:newSection("left", "Debug")
            debug:newButton("settings/debug/copy_pos"):setLabel("Copy Position").changed:Connect(function()
                setclipboard(("Vector3.new(%s)"):format(tostring(rootPart.Position)))
            end)

            debug:newButton("settings/debug/copy_cf"):setLabel("Copy CFrame").changed:Connect(function()
                local x, y, z = rootPart.CFrame:ToOrientation()
                local xr, yr, zr = math.deg(x), math.deg(y), math.deg(z)
                setclipboard(("CFrame.new(%s) * CFrame.Angles(%s)"):format(tostring(rootPart.Position), tostring(Vector3.new(xr, yr, zr))))
            end)

            debug:newButton("settings/debug/fake_megalodon_event"):setLabel("Fake Megalodon Event").changed:Connect(function()
                local part = Instance.new("Part")
                part.Name = "Megalodon"
                part.Anchored = true
                part.CanCollide = false
                part.BrickColor = BrickColor.Blue()
                part.CFrame = LocalPlayer.Character.PrimaryPart.CFrame * CFrame.new(0, 5, 0)
                part.Parent = fishingZones
                task.wait(5)
                part:Destroy()
            end)

            debug:newButton("settings/debug/fake_serpent_event"):setLabel("Fake Serpent Event").changed:Connect(function()
                local part = Instance.new("Part")
                part.Name = "Serpent"
                part.Anchored = true
                part.BrickColor = BrickColor.Red()
                part.CanCollide = false
                part.CFrame = LocalPlayer.Character.PrimaryPart.CFrame * CFrame.new(0, 5, 0)
                part.Parent = fishingZones
                task.wait(10)
                part:Destroy()
            end)
        end
        
		if UserInputService.TouchEnabled then
			menu:newToggle("settings/menu/invis_open"):setLabel("Invisible Open Button").changed:Connect(function(state)
				if state then
					base.instances.open.Text = ""
					base.instances.open.BackgroundTransparency = 1
				else
					base.instances.open.Text = "Open"
					base.instances.open.BackgroundTransparency = 0.5
				end
			end)

			menu:newLabel("settings/menu/mobile_tip1"):setLabel("Open button will still work (located in the to")
			menu:newLabel("settings/menu/mobile_tip2"):setLabel("p center) but will be invisible")
		end

		if isfile and readfile and writefile and listfiles and delfile then
			local configList, saveConfigDropdown, loadConfigDropdown
			local function UpdateLists()
				local foundConfigs = {}
				for _, file in listfiles(HOME_DIR .. "/configs") do
					local split = #file:split("\\") < 2 and file:gsub("\\", ""):split("/") or file:split("\\")
					local fn = split[#split]
					configList:add(fn)
					saveConfigDropdown:add(fn)
					loadConfigDropdown:add(fn)
					foundConfigs[fn] = true
				end

				for filename in configList.options do
					if not foundConfigs[filename] then
						configList:remove(filename)
					end
				end

				for _, filename in saveConfigDropdown.options do
					if not foundConfigs[filename] then
						saveConfigDropdown:remove(filename)
					end
				end

				for _, filename in loadConfigDropdown.options do
					if not foundConfigs[filename] then
						loadConfigDropdown:remove(filename)
					end
				end

				local noConfig = true
				local hasOnlyDefaultCfg = true
				for filename in foundConfigs do
					noConfig = false
					if filename ~= "default.json" then
						hasOnlyDefaultCfg = false
					end
				end

				if noConfig then
					writefile(HOME_DIR .. "/configs/default.json", base:encodeJSON())
					pcall(UpdateLists)
					configList:set("default.json")
					saveConfigDropdown:set("default.json")
					loadConfigDropdown:set("default.json")
				end

				if hasOnlyDefaultCfg and (configList.value ~= "default.json" or saveConfigDropdown.value ~= "default.json" or loadConfigDropdown.value ~= "default.json") then
					configList:set("default.json")
					saveConfigDropdown:set("default.json")
					loadConfigDropdown:set("default.json")
				end
			end

			local configuration = settings:newSection("right", "Configuration")
			local configNameTextbox = configuration:newTextBox("settings/configname"):setLabel("Config Name")
			configuration:newButton("settings/createbtn"):setLabel("Create").changed:Connect(function()
				local configName = configNameTextbox.value
				if configName == "" then return end
				local filePath = HOME_DIR .. "/configs/" .. configName:gsub("%.json", "") .. ".json"
				if not isfile(filePath) then
					writefile(filePath, base:encodeJSON())
					UpdateLists()
				end
			end)

			configList = configuration:newList("settings/configuration", 6, {})
			configuration:newButton("settings/loadbtn"):setLabel("Load").changed:Connect(function()
				local filePath = HOME_DIR .. "/configs/" .. configList.value
				if isfile(filePath) then
					base:decodeJSON(readfile(filePath))
				end
			end)
			configuration:newButton("settings/savebtn"):setLabel("Save").changed:Connect(function()
				local filePath = HOME_DIR .. "/configs/" .. configList.value
				writefile(filePath, base:encodeJSON())
			end)
			configuration:newButton("settings/deletebtn"):setLabel("Delete").changed:Connect(function()
				local filePath = HOME_DIR .. "/configs/" .. configList.value
				if isfile(filePath) then
					delfile(filePath)
				end
			end)

			-- Updates autosave.txt with the config name
			local function AutoSaveChanged()
				if base.features["autosave"].value then
					local configName = saveConfigDropdown.value
					if configName == nil then return end
					if isfile(HOME_DIR .. "/configs/" .. configName) then
						writefile(HOME_DIR .. "/other/autosave.txt", configName)
					else
						writefile(HOME_DIR .. "/other/autosave.txt", "")
					end
				else
					writefile(HOME_DIR .. "/other/autosave.txt", "")
				end
			end

			-- Updates autoload.txt with the config name
			local function AutoLoadChanged()
				if base.features["autoload"].value then
					local configName = loadConfigDropdown.value
					if configName == nil then return end
					if isfile(HOME_DIR .. "/configs/" .. configName) then
						writefile(HOME_DIR .. "/other/autoload.txt", configName)
					else
						writefile(HOME_DIR .. "/other/autoload.txt", "")
					end
				else
					writefile(HOME_DIR .. "/other/autoload.txt", "")
				end
			end

			local shouldAutoSaveBeToggled = false
			if isfile(HOME_DIR .. "/other/autosave.txt") then
				local fileName = readfile(HOME_DIR .. "/other/autosave.txt")
				if fileName ~= "" and isfile(HOME_DIR .. "/configs/" .. fileName) then
					shouldAutoSaveBeToggled = true
				end
			else
				shouldAutoSaveBeToggled = true
			end

			configuration:newToggle("autosave"):set(shouldAutoSaveBeToggled):setLabel("Auto Save To Config").changed:Connect(AutoSaveChanged)
			saveConfigDropdown = configuration:newDropdown("autosave/cfg", false, {})
			saveConfigDropdown.changed:Connect(AutoSaveChanged)
			do -- Set dropdown value to autosave config
				if isfile(HOME_DIR .. "/other/autosave.txt") then
					local configName = readfile(HOME_DIR .. "/other/autosave.txt")
					if configName ~= "" and isfile(HOME_DIR .. "/configs/" .. configName) then
						saveConfigDropdown:set(configName)
					end
				end
			end

			local shouldAutoLoadBeToggled = false
			if isfile(HOME_DIR .. "/other/autoload.txt") then
				local fileName = readfile(HOME_DIR .. "/other/autoload.txt")
				if fileName ~= "" and isfile(HOME_DIR .. "/configs/" .. fileName) then
					shouldAutoLoadBeToggled = true
				end
			else
				shouldAutoLoadBeToggled = true
			end

			configuration:newToggle("autoload"):set(shouldAutoLoadBeToggled):setLabel("Auto Load Config").changed:Connect(AutoLoadChanged)
			loadConfigDropdown = configuration:newDropdown("autoload/cfg", false, {})
			loadConfigDropdown.changed:Connect(AutoLoadChanged)
			do -- Set dropdown value to autoload config
				if isfile(HOME_DIR .. "/other/autoload.txt") then
					local configName = readfile(HOME_DIR .. "/other/autoload.txt")
					if configName ~= "" and isfile(HOME_DIR .. "/configs/" .. configName) then
						loadConfigDropdown:set(configName)
					end
				end
			end

			task.spawn(pcall, UpdateLists)
			task.spawn(LPH_JIT_MAX(function()
				while task.wait(5) do
					pcall(UpdateLists)
				end
			end))

			-- Call after lists were updated otherwise it will fail to set
			AutoSaveChanged()
			AutoLoadChanged()

			local function AutoSave()
				if base.features["autosave"].value then
					if not isfile(HOME_DIR .. "/other/autosave.txt") then return end

					local fileToSave = readfile(HOME_DIR .. "/other/autosave.txt")
					local filePath = HOME_DIR .. "/configs/" .. fileToSave
					if fileToSave == "" or not isfile(filePath) then return end

					writefile(filePath, base:encodeJSON())
				end
			end

			for _, feature in base.features do
				feature.changed:Connect(function()
					AutoSave()
				end)
			end
		end
	end
end

local features = base.features

-- Utility functions

local function SimulateClick(x, y, mouseButton, layer)
    VirtualInputManager:SendMouseButtonEvent(x, y, (mouseButton - 1), true, layer, 1)
    VirtualInputManager:SendMouseButtonEvent(x, y, (mouseButton - 1), false, layer, 1)
end

local function SimulateButtonClick(button, layer)
    VirtualInputManager:SendKeyEvent(false, button, false, layer)
    VirtualInputManager:SendKeyEvent(true, button, false, layer)
end


-- how to call this
local toggleThreads = {}
local function ThreadOnToggle(flag, callback)
	features[flag].changed:Connect(function(state)
		if state then
			toggleThreads[flag] = task.spawn(callback)
		else
			task.cancel(toggleThreads[flag])
		end
	end)
end

local function PressButton(button)
    SimulateClick(button.AbsolutePosition.X + button.AbsoluteSize.X / 2, button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2, 1, button.Parent)
end


local currentToolEquipped = nil
local currentRodObject = nil
local isRodEquipped = false
local itemBeingProcessed = false -- True when another feature needs to equip some other item to perform an action
local hasCratesInInventory = false -- For auto sell all

local toolEquipped = Signal.new()
local rodEquipped = Signal.new()
local rodUnequipped = Signal.new()
local failSafeTriggered = Signal.new()
local itemProcessCompleted = Signal.new() -- Used by auto crate for example because we dont want to auto equip rod if we're trying to open crates 
local backpackAdded = Signal.new()
local recastRod = Signal.new()

local function StartItemProcess()
    itemBeingProcessed = true
end

local function ItemProcessedWait()
    if itemBeingProcessed then itemProcessCompleted:Wait() end
end

local function FinishItemProcess()
    itemBeingProcessed = false
    itemProcessCompleted:Fire()
end

local freezeCFrame = nil
local function FreezePlayer(newFreezeCFrame)
    freezeCFrame = newFreezeCFrame
end

local currentRodState = "None"
local lastRodState = "None"
local lastStateUpdate = tick()

local function SetRodState(rodState)
    currentRodState = rodState
    lastStateUpdate = tick()
end

local function CancelFarming()
    -- local humanoid = character:WaitForChild("Humanoid", 10)
    -- if not humanoid then return end

    -- if currentRodState == "Reeling" then
    --     -- // Wait till player isn't reeling
    --     repeat task.wait() until currentRodState ~= "Reeling"
    -- else
    --     -- // Unequip to cancel animations
    --     currentRodState = "None"
    --     humanoid:UnequipTools()
    -- end
end

local worldChests = workspace:WaitForChild("world").chests
local function OpenTreasureChest(coords)
    local stringifiedCoords = ("%s_%s_%s"):format(coords.X, coords.Y, coords.Z)
    fireproximityprompt(worldChests:WaitForChild("TreasureChest_" .. stringifiedCoords):FindFirstChildOfClass("ProximityPrompt"))
    ReplicatedStorage.events.open_treasure:FireServer({
        ["x"] = coords.X,
        ["y"] = coords.Y,
        ["z"] = coords.Z
    })
end

local function getAvailableBaits()
    local baits = {}
    for _,bait in playerStats.Stats.bait:GetChildren() do
        if bait.Name == 'bait_instant Catcher' then
            continue
        end

        if bait.Value > 0 then
            baits[string.split(bait.Name, '_')[2]] = bait.Value
        end
    end
    return baits
end

local function getHighestAvailableBait()
    local baits = getAvailableBaits()
    local target = nil
    local value = 0
    for i,v in baits do
        if v > value then
            value = v
            target = i
        end
    end
    return target
end

-- Used for freezing player
task.spawn(function()
    while task.wait() do
        if not character then characterAdded:Wait() end
        if not freezeCFrame then continue end

        rootPart.CFrame = freezeCFrame
        rootPart.Velocity = Vector3.zero
    end
end)

-- // Bypass
local RF_SetZone = ReplicatedStorage:WaitForChild("packages").Net["RF/SetZone"]
do
    -- StreamMapAsync(Vector3.new(517, 165, 274))
--     RF_SetZone:InvokeServer(workspace:WaitForChild("zones"):WaitForChild("player"):WaitForChild("Moosewood"))

--     -- StreamMapAsync(Vector3.new(467, 193, 257))
--     RF_SetZone:InvokeServer(workspace:WaitForChild("zones"):WaitForChild("player"):WaitForChild("Moosewood Village"))
-- end
    RF_SetZone.Parent = nil
    local fakeSetZone = Instance.new("RemoteFunction")
    fakeSetZone.Name = "RF/SetZone"
    fakeSetZone.Parent = ReplicatedStorage.packages.Net
end

-- // Handlers
local onGoingEvents = {}
local eventPriorities = {
    ["Megalodon"] = 1,
    ["Whale Shark"] = 2,
    ["Great White Shark"] = 3,
    ["Serpent"] = 4,
    ["Meteor"] = 5,
}
local beforeEventCFrame = nil

-- Keep them defined here
local AddEvent, RemoveEvent

local function PauseEvent()
    if features["farming/other/freeze_plr"].value then
        FreezePlayer(beforeEventCFrame)
    else
        FreezePlayer(nil)
        TeleportCFrame(beforeEventCFrame)
    end

    beforeEventCFrame = nil

    CancelFarming()

    activeEvent = "None"
    activeEventChanged:Fire(activeEvent)

    if not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, not features["misc/player/disable_swimming"].value)
end

-- if we have more events
-- local eventBehaviors = {
--     ["Meteor"] = function() end
-- }

local function SetBeforeEventCFrame(cframe)
    beforeEventCFrame = cframe
end

local function SelectNextEvent()
    if #onGoingEvents == 0 then
        warn("No events, pausing")
        PauseEvent()
        return
    end

    table.sort(onGoingEvents, function(a, b)
        return a.Priority < b.Priority
    end)

    if not character then characterAdded:Wait() end
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    local nextEvent = onGoingEvents[1]
    warn("NEXT EVENT IS GONNA BE", nextEvent)
    if nextEvent and activeEvent ~= nextEvent then
        if activeEvent ~= "None" and (eventPriorities[activeEvent] or 999) <= (eventPriorities[nextEvent.Name] or 999) then return end
        if activeEvent == "None" and not beforeEventCFrame then SetBeforeEventCFrame(rootPart.CFrame) end

        activeEvent = nextEvent.Name
        activeEventChanged:Fire(activeEvent)

        if activeEvent == "Meteor" then
            local proximityPrompt = nextEvent.Marker:FindFirstChildWhichIsA("ProximityPrompt", true)
            FreezePlayer(nextEvent.Position)
            task.wait(0.5)
            for i = 1, 10 do
                fireproximityprompt(proximityPrompt)
                task.wait(0.1)
            end

            RemoveEvent(nextEvent.Marker)
        else
            if isRodEquipped then
                CancelFarming()
            end

            humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
            humanoid:ChangeState(Enum.HumanoidStateType.Running)

            FreezePlayer(nextEvent.Position)
        end
        print("Now handling event:", nextEvent.Name)
    else
        PauseEvent()
    end
end

local function ClearEventByName(name)
    for i, event in onGoingEvents do
        if event.Name == name then
            table.remove(onGoingEvents, i)
        end
    end

    if activeEvent == name then
        PauseEvent()
    end
end

local function GetEventPriority(eventName)
    return eventPriorities[eventName] or 999
end

function AddEvent(eventName, eventMarker, eventPosition, priority)
    warn("Adding event", eventName, "with marker", eventMarker)
    table.insert(onGoingEvents, {
        Name = eventName,
        Position = eventPosition,
        Marker = eventMarker,
        Priority = priority or GetEventPriority(eventName)
    })

    SelectNextEvent()
end

function RemoveEvent(eventMarker)
    warn("Removing event", eventMarker)
    local removedEventName = nil
    for i, event in onGoingEvents do
        if event.Marker == eventMarker then
            removedEventName = event.Name
            table.remove(onGoingEvents, i)
            break
        end
    end

    if removedEventName and removedEventName == activeEvent then
        warn("Selecting the next event")
        activeEvent = "None" -- Set to None because we removed the event that was active
        SelectNextEvent()
    end
end

-- // Hooks

-- // Loops
LPH_JIT_MAX(function()
	task.spawn(function()
        local consecutiveFails = 0
		while true do

            if tick() - lastStateUpdate <= 10 then task.wait(1) continue end

			if currentRodState ~= "None" and lastRodState == currentRodState then
				failSafeTriggered:Fire()
                consecutiveFails += 1
                warn("Fail safe triggered")
            else
                consecutiveFails = 0
			end

            -- Reconnect if there are consecutive fails
            if consecutiveFails >= 10 then
                print("RECONNECT")
                break
            end

            lastRodState = currentRodState
			task.wait(1)
		end
	end)

	ThreadOnToggle("misc/player/walk_on_water", function()
		while task.wait() do
            if not character then characterAdded:Wait() end

            local origin = character.Head.Position 
            local dir = Vector3.new(0, -5, 0)
            
            local raycastParams = RaycastParams.new() 
            raycastParams.FilterDescendantsInstances = {character, workspace.world, workspace.zones}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist 

            local result = workspace:Raycast(origin, dir, raycastParams)
            if result and result.Material == Enum.Material.Water then 
                waterWalkPart.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0)
            end
		end
	end)

	ThreadOnToggle("market/inventory/auto_sell", function()
		while true do
            if features["market/inventory/auto_sell"].value then
                if not character then characterAdded:Wait() end
                local backpack = LocalPlayer:WaitForChild("Backpack")

                if features["market/inventory/disable_sell_if_crates"].value and hasCratesInInventory then
                    task.wait(5)
                    continue
                end

                if HasFishToSell() then

                    local unanchorTask = task.spawn(function()
                        while rootPart do
                            rootPart.Anchored = false
                            task.wait()
                        end
                    end)

                    local merchant = GetMerchant()
                    pcall(function()
                        merchant:FindFirstChild("sellall", true):InvokeServer()
                    end)
                    
                    task.cancel(unanchorTask)
                end
            end

			task.wait(5)
        end
    end)

    ThreadOnToggle("misc/other/auto_crate", function()
        while true do
            if not character then characterAdded:Wait() end

            for _, tool in LocalPlayer.Backpack:GetChildren() do
                if tool.Name:find("Crate") and not tool.Name:find("Skin") then
                    local crate = tool.link.Value
                    ItemProcessedWait()
                    StartItemProcess()
                    for i = 1, crate.Stack.Value do
                        humanoid:EquipTool(tool)
                        task.wait(0.01)
                        tool:Activate()

                        -- // Open skin crates
                        -- if tool.Name:find("Skin Crate") then
                        --     ReplicatedStorage.packages.Net["RF/SkinCrates/RequestSpin"]:InvokeServer()
                        --     task.wait(5)
                        -- end
                    end
                    FinishItemProcess()
                end
            end

            task.wait(2)
        end
    end)

	local function FormatTime(v8)
		local v9 = math.floor(v8 / 60 / 60)
		local v10 = os.date("%M", v8)
		local v11 = os.date("%S", v8)
		return (tonumber(v9) or 0) >= 1 and ("%*:%*:%*"):format(v9, v10, v11) or ("%*:%*"):format(v10, v11)
	end

	ThreadOnToggle("misc/other/fish_radar", function()
		while true do
			local serverTime = workspace:GetServerTimeNow()
			for _, inst in CollectionService:GetTagged("radarTagWithTimer") do
				local parent = inst.Parent
				if parent then
					local text = parent:GetAttribute("Text")
					if text then
						local endClock = parent:GetAttribute("EndClock")
						if endClock then
							local expiry = math.clamp(endClock - serverTime, 0, 1e999)
							inst.abundanceName.Text = expiry <= 0 and "Disappearing Soon" or text:format(FormatTime(expiry))
						end
					end
				end
			end

			task.wait(1)
		end
	end)
end)()

do -- Physics shit
	local UpdateFlight
	do
		local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))

		local function GetFlyDirection(deltaTime)
			local speed = features["misc/movement/flight/value"].value
			local cameraCFrame = CurrentCamera.CFrame
			local velocity = Vector3.zero

			if UserInputService:GetFocusedTextBox() == nil then
				if UserInputService.KeyboardEnabled then
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then
						velocity += cameraCFrame.LookVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then
						velocity -= cameraCFrame.RightVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then
						velocity -= cameraCFrame.LookVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then
						velocity += cameraCFrame.RightVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.E) then
						velocity += cameraCFrame.UpVector
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
						velocity -= cameraCFrame.UpVector
					end
				else
					local moveVector = PlayerModule:GetControls():GetMoveVector()

					if moveVector.Magnitude > 0 then
						velocity += cameraCFrame.LookVector * -moveVector.Z
						velocity += cameraCFrame.RightVector * moveVector.X
					end
				end
			end

			return velocity * speed / 100 * deltaTime * 60
		end

		function UpdateFlight(deltaTime)
			local rootPart: BasePart = character and character:FindFirstChild("HumanoidRootPart")
			if not rootPart then return end

			rootPart.AssemblyLinearVelocity = Vector3.new(0, workspace.Gravity * deltaTime / 7, 0)
			rootPart.CFrame += GetFlyDirection(deltaTime)
		end
	end

	local flightToggle = features["misc/movement/flight"]
	local flightBind = features["misc/movement/flight/bind"]
	local noclipToggle = features["misc/movement/noclip"]
	local noclipBind = features["misc/movement/noclip/bind"]
	local collisionData = {}
	RunService.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
		if flightToggle.value and flightBind.active then
			UpdateFlight(deltaTime)
		end

        -- Noclip can't be used while theres an active event otherwise the rod bugs out
		if noclipToggle.value and noclipBind.active and activeEvent == "None" then
			if not collisionData then collisionData = {} end
			if not character then return end
			for _, v in character:GetDescendants() do
				if v:IsA("BasePart") and v.CanCollide and not v:IsDescendantOf(currentRodObject) then
					collisionData[v] = true
					v.CanCollide = false
				end
			end
		elseif collisionData then
			for v in collisionData do
				v.CanCollide = true
			end
			collisionData = nil
		end
	end))

	LocalPlayer.CharacterRemoving:Connect(function()
		collisionData = nil
	end)
end

-- // Callbacks
LPH_JIT_MAX(function()
    LocalPlayer.ChildAdded:Connect(function(child)
        if child:IsA("Backpack") then
            backpackAdded:Fire(child)
        end
    end)

	-- // Updates tool equipped
	do
		local function OnChildAdded(child)
			local rodName = playerStats.Stats.rod.Value
			if child:IsA("Tool") then
				currentToolEquipped = child
				toolEquipped:Fire(currentToolEquipped)

				if child.Name == rodName then
					currentRodObject = child
					if child.Parent ~= LocalPlayer:FindFirstChild("Backpack") then
						isRodEquipped = true
						rodEquipped:Fire(currentRodObject)
					else
						isRodEquipped = false
						currentRodState = "None"
						rodUnequipped:Fire(currentRodObject)
					end
				end
			end
		end

		-- // Character
		if character then
			for _, v in character:GetChildren() do OnChildAdded(v) end
			character.ChildAdded:Connect(OnChildAdded)
		end

		LocalPlayer.CharacterAdded:Connect(function(character)
			character.ChildAdded:Connect(OnChildAdded)
		end)

		-- // Backpack
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		if backpack then
			for _, v in backpack:GetChildren() do OnChildAdded(v) end
			backpack.ChildAdded:Connect(OnChildAdded)
		end

		backpackAdded:Connect(function(backpack)
			backpack.ChildAdded:Connect(OnChildAdded)
		end)
	end

    do
        local function CharacterAdded(Character)
            local Humanoid = Character:WaitForChild("Humanoid", 5)
            if not Humanoid then return end
            if activeEvent == "None" then
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, not features["misc/player/disable_swimming"].value)
            end
        end

        LocalPlayer.CharacterAdded:Connect(CharacterAdded)
        if character then task.spawn(CharacterAdded, character) end
    end

	-- // Auto cast
	do
		local random = Random.new()

        local castHoldAnimation
        local throwAnimation
        local waitingAnimation

		local function CastRod(rod)
            ItemProcessedWait()

			local perfectCastChance = features["farming/auto_cast/accuracy/perfect"].value
			local castPower = random:NextNumber(1, 100) <= perfectCastChance and random:NextNumber(96.01, 99.98) or random:NextNumber(80, 96)

			local castType = features["farming/auto_cast/type"].value
			if castType == "Blatant" then
                -- Server hop after 15 attempts
                local attempts = 0

                while not rod:WaitForChild("values").casted.Value and attempts < 15 do
                    rod.events.cast:FireServer(castPower, 1)
                    attempts += 1
                    task.wait(1)
                end

                if attempts == 15 then
                    print("Server Hop")
                end
			elseif castType == "Legit" or castType == "Semi-Legit" then
				castHoldAnimation = character.Humanoid:LoadAnimation(animations.fishing.casthold)
				castHoldAnimation.Priority = Enum.AnimationPriority.Action2
				castHoldAnimation:Play(0.3)
				task.wait(0.1)

				local powerBarUI = ReplicatedStorage.resources.replicated.fishing.power:Clone()
				powerBarUI.powerbar.bar.Size = UDim2.new(1, 0, 0, 0)
				powerBarUI.Enabled = true
				powerBarUI.Parent = character.HumanoidRootPart

				local power = random:NextInteger(6, 13)
				local powerIncrement = random:NextInteger(10, 40) / 10

				repeat
					task.wait(0.01)
					power = power + powerIncrement
					powerBarUI.powerbar.bar.Size = UDim2.new(1, 0, math.clamp(power / 100, 0, 1), 0)
				until power >= castPower
				castHoldAnimation:Stop()
				powerBarUI:Destroy()

				task.spawn(function()
                    local attempts = 0
                    while not rod.values.casted.Value and attempts < 15 do
                        rod.events.cast:FireServer(power, 1)
                        attempts += 1
                        task.wait(0.5)
                    end

                    if attempts == 15 then
                        print("Server Hop")
                    end 
                end)

				throwAnimation = character.Humanoid:LoadAnimation(animations.fishing.throw)
				throwAnimation.Priority = Enum.AnimationPriority.Action3
				throwAnimation:Play()

				task.wait(0.69)

				if isRodEquipped then
					waitingAnimation = character.Humanoid:LoadAnimation(animations.fishing.waiting)
					waitingAnimation.Priority = Enum.AnimationPriority.Action3
					waitingAnimation:Play()
				end

				-- fuk this
				-- local powerFeedback = ReplicatedStorage.resources.replicated.fishing.powerfeedback:Clone()
				-- powerFeedback.title.TextTransparency = 1
				-- powerFeedback.title.UIStroke.Transparency = 1
				-- powerFeedback.StudsOffsetWorldSpace = Vector3.new(0, 2.5999999046325684, 0, 0)
				-- powerFeedback.Parent = LocalPlayer.Character.HumanoidRootPart

				-- if castPower > 80 and castPower <= 96 then
				-- 	powerFeedback.title.Text = "Amazing!!"
				-- 	local perfectCastEffect = ReplicatedStorage.resources.replicated.fx.perfectcast:Clone()
				-- 	perfectCastEffect.Enabled = false
				-- 	perfectCastEffect.Parent = LocalPlayer.Character.Torso
				-- 	perfectCastEffect:Emit(math.random(2, 3))
				-- 	Debris:AddItem(perfectCastEffect, 1)
				-- elseif castPower > 96 then
				-- 	powerFeedback.title.Text = "PERFECT!"
				-- 	l_fx_0:PlaySound(l_sfx_0.fishing.perfectcast, l_Parent_0.handle, true)
				-- 	local v44 = l_ReplicatedStorage_0.resources.replicated.fx.perfectcast:Clone()
				-- 	v44.Enabled = false
				-- 	v44.Parent = v1.Torso
				-- 	v44:Emit(math.random(9, 16))
				-- 	l_debris_0:AddItem(v44, 1)
				-- end
			else

			end
		end

		local function AutoCast(rod)
			if not isRodEquipped then return end

			local values = rod:WaitForChild("values", 10)
			if not values then return end

			if not values.casted.Value then
				currentRodState = "None"
				if features["farming/fishing/auto_cast"].value then
					local castDelay = features["farming/auto_cast/delay"].value
					task.delay(castDelay, CastRod, rod)
					SetRodState("Casting")
				end
			end
		end

		local rodCastedChanged = nil
		local function OnRodEquipped(rod)
			if rodCastedChanged then
				rodCastedChanged:Disconnect()
			end

			AutoCast(rod)
			rodCastedChanged = rod:WaitForChild("values").casted:GetPropertyChangedSignal("Value"):Connect(function()
				AutoCast(rod)
			end)
		end

		if currentRodObject then
			task.spawn(OnRodEquipped, currentRodObject)
		end

		rodEquipped:Connect(OnRodEquipped)
		failSafeTriggered:Connect(function()
			if features["farming/fishing/auto_cast"].value and isRodEquipped and currentRodState == "Casting" then
                lastRodState = "None"
                if castHoldAnimation and throwAnimation and waitingAnimation then
                    castHoldAnimation:Stop()
                    throwAnimation:Stop()
                    waitingAnimation:Stop()
                end

                CancelFarming()
                task.wait()
                humanoid:EquipTool(currentRodObject)

                task.wait(2)

                AutoCast(currentRodObject)
			end
		end)

        features["farming/fishing/auto_cast"].changed:Connect(function(state)
            if state and isRodEquipped then
                CastRod(currentRodObject)
            end
        end)

        -- Fired when item process is done
        recastRod:Connect(function()
            -- if features["farming/fishing/auto_cast"].value and isRodEquipped then
            --     CastRod(currentRodObject)
            -- end
        end)
	end

	-- // Auto Shake
	do
		local function ShakeInteract(button)
            SetRodState("Shaking")
			if features["farming/auto_shake/type"].value == "Click" then
				while task.wait() do
					local safezone = button.Parent -- safezone
					local withinBounds = (
						button.AbsolutePosition.X >= safezone.AbsolutePosition.X and
						button.AbsolutePosition.Y >= safezone.AbsolutePosition.Y and
						button.AbsolutePosition.X + button.AbsoluteSize.X <= safezone.AbsolutePosition.X + safezone.AbsoluteSize.X and
						button.AbsolutePosition.Y + button.AbsoluteSize.Y <= safezone.AbsolutePosition.Y + safezone.AbsoluteSize.Y)
					if withinBounds then break end
				end

				while button.Parent ~= nil do
					PressButton(button)
					task.wait()
				end
			else
				pcall(function()
					GuiService.SelectedObject = button.Parent
					task.wait()
					GuiService.SelectedObject = button
				end)

				while GuiService.SelectedObject ~= nil and button.Parent ~= nil do
					SimulateButtonClick(Enum.KeyCode.Return, button.Parent)
					task.wait()
				end
			end
		end

		features["farming/auto_shake"].changed:Connect(function()
			local shakeUI = PlayerGui:FindFirstChild("shakeui")
			local shakeBounds = shakeUI and shakeUI:WaitForChild("safezone")
			local button = shakeBounds and shakeBounds:FindFirstChild("button")
			if not button then return end

			ShakeInteract(button)
		end)

		PlayerGui.ChildAdded:Connect(function(child)
			if child.Name == "shakeui" then
				child:WaitForChild("safezone").ChildAdded:Connect(function(child2)
					if child2.Name == "button" and features["farming/auto_shake"].value then
						ShakeInteract(child2)
					end
				end)
			end
		end)

		failSafeTriggered:Connect(function()
            if currentRodState == "Shaking" then
                local shakeUI = PlayerGui:FindFirstChild("shakeui")
                local safezone = shakeUI and shakeUI:FindFirstChild("safezone")
                local button = safezone and safezone:FindFirstChild("button")

                if features["farming/auto_shake"].value and button then
                    lastRodState = "None"
                    ShakeInteract(button)
                end
            end
		end)
	end

	-- // Auto Reel
	do
		local function Reel()
			SetRodState("Reeling")
			ReplicatedStorage.events.reelfinished:FireServer(100, false)
		end

		PlayerGui.ChildAdded:Connect(function(child)
			if features["farming/auto_reel"].value and child.Name == "reel" then
				child:WaitForChild("bar"):WaitForChild("reel")

				if not LocalPlayer.Character:GetAttribute("Reeling") then
					LocalPlayer.Character:GetAttributeChangedSignal("Reeling"):Wait()
				end
				task.wait(1.5)
				for _ = 1, 10 do
					Reel()
					task.wait(0.1)
				end
			end
		end)

		failSafeTriggered:Connect(function()
            if currentRodState == "Reeling" then
                local isReeling = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Reeling")
                if features["farming/auto_reel"].value and isReeling then
                    lastRodState = "None"
                    Reel()
                end
            end
		end)
	end

	-- // Treasure map utility
	do
		local coords = nil
		local isRepaired = false

		local function OnChildAdded(child)
			if child.Name ~= "Treasure Map" then return end

			local main = child:WaitForChild("Main", 10)
			if not main then return end

			local textButton = Instance.new("TextButton")
            textButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            textButton.Position = UDim2.fromScale(1, 0.5)
            textButton.AnchorPoint = Vector2.new(0.5, 0.5)
            textButton.Size = UDim2.fromScale(0.3, 0.1)
            textButton.TextSize = 15
            textButton.TextColor3 = Color3.fromRGB(0, 255, 0)
            textButton.BorderColor3 = Color3.fromRGB(30, 30, 30)
            textButton.Visible = false

			child:GetPropertyChangedSignal("Enabled"):Connect(function()
				if child.Enabled then
					if isRepaired then
						textButton.Text = "Claim"
					else
						textButton.Text = "Repair (C$250)"
					end
				end
			end)

			-- features["misc/other/treasure_map_helper"].changed:Connect(function(state)
            --     if textButton then return end
                
            --     -- Only parent this when its needed
            --     textButton.Parent = main

            --     textButton.MouseButton1Click:Connect(function()
            --         if textButton.Text == "Claim" and coords then
            --             OpenTreasureChest(coords)
            --             coords = nil
            --         elseif textButton.Text == "Repair (C$250)" then
            --             local jackMarrow = GetJackMarrowNPC()

            --             pcall(function()
            --                 if jackMarrow.treasure.repairmap:InvokeServer() then
            --                     textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            --                     textButton.Text = "Claim"
            --                 else
            --                     textButton.TextColor3 = Color3.fromRGB(255, 0, 0)
            --                     textButton.Text = "Failed to repair!"
            --                     task.wait(1)
            --                     textButton.TextColor3 = Color3.fromRGB(0, 255, 0)
            --                     textButton.Text = "Repair (C$250)"
            --                 end
            --             end)
            --         end
            --     end)
			-- 	textButton.Visible = state
			-- end)
		end

		local treasureMap = PlayerGui:FindFirstChild("Treasure Map")
		if treasureMap then OnChildAdded(treasureMap) end
		PlayerGui.ChildAdded:Connect(OnChildAdded)

        local function OnToolEquipped(tool)
            if tool.Name == "Treasure Map" then
				local link = tool:FindFirstChild("link")
				if not link then return end

				local treasureMapData = link.Value
				coords = {X = treasureMapData.x.Value, Y = treasureMapData.y.Value, Z = treasureMapData.z.Value}
                isRepaired = treasureMapData.Repaired.Value
			end
        end

		toolEquipped:Connect(OnToolEquipped)
        if character then
            for _, v in character:GetChildren() do
                if v:IsA("Tool") then OnToolEquipped(v) end
            end
        end
	end

    do -- Auto Treasure Map shit
        local processingMaps = {}

        local function ItemAdded(item)
            if not processingMaps[item] and item.Name == "Treasure Map" and features["misc/other/auto_claim_treasure_maps"].value then
                task.wait()
                if coins.Value < 250 then return end
                if not humanoid then return end

                local link = item:WaitForChild("link", 10)
                if not link then return end

                local treasureMapData = link.Value
                if not treasureMapData then return end

                local repairedBool = treasureMapData:WaitForChild("Repaired", 10)
                if not repairedBool then return end

                processingMaps[item] = true

                ItemProcessedWait()

                StartItemProcess()
                humanoid:EquipTool(item)
                task.wait()

                if not repairedBool.Value then
                    local status, success = pcall(function()
                        local jackMarrow = FindNPC("Jack Marrow", {
                            Vector3.new(465, 152, 228),
                            Vector3.new(-2826, 214, 1518)
                        })
                        return jackMarrow.treasure.repairmap:InvokeServer()
                    end)

                    if not status or success == false then
                        warn("Failed to open treasure chest:", status, success)
                        processingMaps[item] = nil
                        return
                    end
                end

                local coords = {X = treasureMapData.x.Value, Y = treasureMapData.y.Value, Z = treasureMapData.z.Value}
                OpenTreasureChest(coords)
                task.wait()
                humanoid:UnequipTools()

                FinishItemProcess()
                processingMaps[item] = nil
            end
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in backpack:GetChildren() do
                task.delay(0.01, ItemAdded, item)
            end
            backpack.ChildAdded:Connect(ItemAdded)
        end

        backpackAdded:Connect(function(backpack)
            backpack.ChildAdded:Connect(ItemAdded)
        end)

        features["misc/other/auto_claim_treasure_maps"].changed:Connect(function(state)
            if state then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, item in backpack:GetChildren() do
                        ItemAdded(item)
                    end
                end
            end
        end)
    end

	do -- Fish radar
		CollectionService:GetInstanceAddedSignal("radarTag"):Connect(function(child)
			if features["misc/other/fish_radar"].value and (child:IsA("BillboardGui") or child:IsA("SurfaceGui")) then
				child.Enabled = true
			end
		end)

		CollectionService:GetInstanceAddedSignal("radarTagWithTimer"):Connect(function(child)
			if features["misc/other/fish_radar"].value and (child:IsA("BillboardGui") or child:IsA("SurfaceGui")) then
				child.Enabled = true
			end
		end)

		features["misc/other/fish_radar"].changed:Connect(function(state)
			for _, inst in CollectionService:GetTagged("radarTag") do
                if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
					if inst:IsA("BillboardGui") then
						inst.MaxDistance = state and math.huge or 250
					else
						inst.MaxDistance = state and math.huge or 200
					end
                    inst.Enabled = state
                end
            end
		end)
	end

    do -- Auto Bait
        local bait = playerStats.Stats.bait
        local autoBaitEnabled = features['farming/auto_bait']

        local function BaitChanged()
            if autoBaitEnabled.value then 
                local selectedBait = nil

                selectedBait = features['farming/auto_bait/type'].value 

                if features['farming/auto_bait/use_available'].value then 
                    selectedBait = getHighestAvailableBait() 
                elseif features['farming/auto_bait/best_bait_for_events'].value then 
                    if bestEventBaits[activeEvent] then 
                        for _, preferredBait in bestEventBaits[activeEvent] do
                            if HasBait(preferredBait) then 
                                selectedBait = preferredBait
                                break
                            end 
                        end 
                    end 
                end

                if bait.Value ~= selectedBait then
                    print("bait changed", bait.Value, "to", selectedBait)
                    PlayerGui.hud.safezone.equipment.bait.scroll.safezone.e:FireServer(selectedBait)
                end
            end 
        end

        bait:GetPropertyChangedSignal('Value'):Connect(BaitChanged)
        for _, featureName in {
            "farming/auto_bait",
            "farming/auto_bait/type",
            "farming/auto_bait/best_bait_for_events"
        } do
            features[featureName].changed:Connect(BaitChanged)
        end
        activeEventChanged:Connect(BaitChanged)
    end 

    do -- Auto Appraise 
        local appraiseType = features['market/appraise/appraise_type']

        local function AppraiseEqCheck(status, old, inc, new)
            if status == 'appraised' then 
                return tonumber(string.format("%.1f", old+inc))==new
            else 
                return tonumber(string.format("%.1f", old-inc))==new
            end 
        end 
        
        local coinsChangedConnection = nil

        local lastWeight = 0
        local function AppraiseEquipped()
            local minCash = ToNumber(features['market/appraise/min_cash'].value)            
            if coins.Value >= minCash and features['market/appraise/auto_appraise'].value then 
                local fish = LocalPlayer.Character:FindFirstChildWhichIsA('Tool')
                if fish and fish:FindFirstChild('link') then 
                    LocalPlayer.Backpack.ChildRemoved:Once(function(item)
                        local itemLink = item.link.Value 
                        local originalWeight = itemLink.Weight.Value
            
                        local status = 'None' -- status of appraisement
                        local appraiseWeight = nil -- weight factor
                        while not appraiseWeight and status == 'None' do
                            local notification = ReplicatedStorage.events.anno_thought.OnClientEvent:Wait()
                            appraiseWeight = tonumber(string.match(notification, "(%d+%.?%d*)kg"))
                            if appraiseWeight then 
                                if notification:find("appraised") then 
                                    status = 'appraised'
                                else 
                                    status = 'deppressed'
                                end 
                            end 
                        end
            
                        LocalPlayer.Backpack.ChildAdded:Once(function(newItem)
                            task.wait()
                            local newWeight = newItem.link.Value.Weight.Value 
                            local minWeight = ToNumber(features['market/appraise/min_weight'].value)
                            if newWeight >= minWeight then 
                                coinsChangedConnection:Disconnect()
                                features['market/appraise/auto_appraise']:set(false)
                            end 
                            LocalPlayer.Character.Humanoid:EquipTool(newItem)
                        end)
                    end)
                    
                    local appraiser = GetAppraiser() 
                    appraiser.appraiser.appraise:InvokeServer()
                end 
            end 
        end 
        
        
        
        for _, featureName in {
            'market/appraise/auto_appraise',
            'market/appraise/min_cash'
        } do 
            features[featureName].changed:Connect(function(state)
                if coinsChangedConnection then coinsChangedConnection:Disconnect() end
 
                if state then 
                    print('nighga')
                    coinsChangedConnection = coins:GetPropertyChangedSignal('Value'):Connect(function()
                        task.wait(.15)
                        AppraiseEquipped()
                    end)
                    AppraiseEquipped()
                end
            end)
        end 
    end 

	do -- Auto Purchase Totems
		local justBought = false

		local function AttemptPurchaseTotem()
			local minCash = ToNumber(features["market/totems/auto_purchase/min_cash"].value)
			if not justBought and minCash and features["market/totems/auto_purchase"].value and coins.Value >= minCash then
				justBought = true
				task.delay(5, function()
					justBought = false
				end)

				for totem in features["market/totems/multi_selection"].value do
                    if coins.Value >= itemsLibrary.Items[totem].Price and not HasItem(totem) then
					    ReplicatedStorage.events.purchase:FireServer(totem, "Item", nil, 1)
                    else
                        warn("Has totem or doesnt need it")
                    end
				end
			end
		end

		coins:GetPropertyChangedSignal("Value"):Connect(AttemptPurchaseTotem)

		for _, featureName in {
			"market/totems/multi_selection",
			"market/totems/auto_purchase/min_cash",
			"market/totems/auto_purchase",
		} do
			features[featureName].changed:Connect(AttemptPurchaseTotem)
		end
	end

    do -- Freeze player
        features["farming/other/freeze_plr"].changed:Connect(function(state)
            if activeEvent == "None" then
                if state then
                    if not character then characterAdded:Wait() end
                    FreezePlayer(character:GetPivot())
                else
                    FreezePlayer(nil)
                end
            end
        end)
    end

    do -- Infinite oxygen
        local oxygenScript = character and character:WaitForChild("client").oxygen
        local zonesScript = character and character:WaitForChild("client").ZONES_REWORK
        characterAdded:Connect(function(character)
            oxygenScript = character:WaitForChild("client").oxygen
            zonesScript = character and character:WaitForChild("client").ZONES_REWORK
            oxygenScript.Enabled = features["misc/player/infinite_oxygen"].value
            zonesScript.Enabled = false
        end)

        features["misc/player/infinite_oxygen"].changed:Connect(function(state)
            oxygenScript.Enabled = not state

            if state and character then
                for _, v in character.Head:GetChildren() do
                    if v.Name == "ui" then v:Destroy() end
                end
            end
        end)
    end

    do -- Events
        local autoMegalodonFeature = features["farming/events/auto_megalodon"]
        local autoDepthSerpentFeature = features["farming/events/auto_depth_serpent"]
        local autoGreatWhiteSharkFeature = features["farming/events/auto_great_white_shark"]
        local autoMeteorFeature = features["farming/events/auto_meteor"]

        local fishingZones = fishingZones

        local function OnChildAdded(child)
            if child.Name:find("Megalodon") and autoMegalodonFeature.value then
                AddEvent("Megalodon", child, child.CFrame + Vector3.new(0, -5, 0))
                child.Destroying:Connect(function()
                    RemoveEvent(child)
                end)
            elseif child.Name:find("Serpent") and autoDepthSerpentFeature.value then
                AddEvent("Serpent", child, child.CFrame + Vector3.new(0, -5, 0))
                child.Destroying:Connect(function()
                    RemoveEvent(child)
                end)
            elseif child.Name:find("Whale Shark") and autoDepthSerpentFeature.value then
                AddEvent("Whale Shark", child, child.CFrame + Vector3.new(0, -5, 0))
                child.Destroying:Connect(function()
                    RemoveEvent(child)
                end)
            elseif child.Name:find("Great White Shark") and autoGreatWhiteSharkFeature.value then
                AddEvent("Great White Shark", child, child.CFrame + Vector3.new(0, -5, 0))
                child.Destroying:Connect(function()
                    RemoveEvent(child)
                end)
            elseif child.Parent.Name == "MeteorItems" and autoMeteorFeature.value then
                AddEvent("Meteor", child, child:GetPivot() + Vector3.new(0, 3, 0))
                child.Destroying:Connect(function()
                    RemoveEvent(child)
                end)
            end
        end

        local function ScanForEvents()
            for _, v in fishingZones:GetChildren() do
                task.spawn(OnChildAdded, v)
            end

            for _, v in workspace.MeteorItems:GetChildren() do
                task.spawn(OnChildAdded, v)
            end
        end

        fishingZones.ChildAdded:Connect(OnChildAdded)
        workspace.MeteorItems.ChildAdded:Connect(OnChildAdded)
        ScanForEvents()

        features["farming/events/auto_megalodon"].changed:Connect(function(state)
            if state then
                -- Scan for events we missed when it was disabled
                ScanForEvents()
            else
                ClearEventByName("Megalodon")
            end
        end)

        features["farming/events/auto_depth_serpent"].changed:Connect(function(state)
            if state then
                -- Scan for events we missed when it was disabled
                ScanForEvents()
            else
                ClearEventByName("Serpent")
            end
        end)

        features["farming/events/auto_meteor"].changed:Connect(function(state)
            if state then
                -- Scan for events we missed when it was disabled
                ScanForEvents()
            else
                ClearEventByName("Meteor")
            end
        end)
    end

    do -- Auto Equip Rod
        local autoEquipRodFeature = features["farming/fishing/auto_equip_rod"]

        rodUnequipped:Connect(function()
            if autoEquipRodFeature.value and currentRodObject then
                local humanoid = character and character:FindFirstChild("Humanoid")
                if not humanoid then return end

                while LocalPlayer:FindFirstChild("Backpack") and currentRodObject.Parent == LocalPlayer.Backpack do
                    ItemProcessedWait()
                    humanoid:EquipTool(currentRodObject)
                    task.wait()
                end
            end
        end)

        autoEquipRodFeature.changed:Connect(function(state)
            if state and not isRodEquipped and currentRodObject then
                local humanoid = character and character:FindFirstChild("Humanoid")
                if not humanoid then return end

                ItemProcessedWait()
                humanoid:EquipTool(currentRodObject)
            end
        end)

        if not isRodEquipped and autoEquipRodFeature.value then
            local humanoid = character and character:FindFirstChild("Humanoid")
            if not humanoid then return end

            ItemProcessedWait()
            humanoid:EquipTool(currentRodObject)
        end
    end

    do -- Stats
        local coinsPerHourLabel = features["stats/gains/coins_per_hr"]
        local coinsOverallLabel = features["stats/gains/coins_overall"]

        local startCoins = coins.Value
        local startTime = nil -- Set upon first gain
        local lastAvg = 0

        coins:GetPropertyChangedSignal("Value"):Connect(function()
            local currentTime = os.time()
            if not startTime then startTime = currentTime end

            local coinChange = coins.Value - startCoins
            local elapsedTime = currentTime - startTime

            local elapsedHours = elapsedTime / 3600

            coinsOverallLabel:setLabel("C$ " .. FormatNumber(coinChange))

            if elapsedHours > 1 then
                startTime = currentTime
            end

            if elapsedHours > 0 then
                local avgCoinsPerMinute = coinChange / elapsedHours
                local hasGained = avgCoinsPerMinute > lastAvg
                lastAvg = avgCoinsPerMinute

                coinsPerHourLabel:setLabel("C$ " .. FormatNumber(avgCoinsPerMinute))
                task.wait(0.1)
                coinsPerHourLabel:setColor(hasGained and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
                task.wait(0.25)
                coinsPerHourLabel:setColor(Color3.fromRGB(255, 250, 179))
            end
        end)
    end

    do -- Area farming
        local allAreasFeature = features["farming/areas/all"]
        local farmInAreaFeature = features["farming/areas/farm_in_area"]

        local function FarmInArea()
            local oldBeforeEventCFrame = beforeEventCFrame
            RemoveEvent("AreaFarm")

            if farmInAreaFeature.value then
                if oldBeforeEventCFrame then SetBeforeEventCFrame(oldBeforeEventCFrame) end

                local zone = fishingZones:FindFirstChild(allAreasFeature.value)
                if not zone then return end

                AddEvent(allAreasFeature.value, "AreaFarm", CFrame.new(zone.CFrame.Position + Vector3.new(0, zone.Size.Y / 2 - 5, 0)), 999)
            end
        end

        allAreasFeature.changed:Connect(FarmInArea)
        farmInAreaFeature.changed:Connect(FarmInArea)
    end
    
    do -- Pos farming
        local customPosDropdown = features["farming/areas/custom_position"]
        local farmInCustomPosToggle = features["farming/areas/farm_in_custom_pos"]

        local function FarmInCustomPos()
            local oldBeforeEventCFrame = beforeEventCFrame
            RemoveEvent("CustomPosFarm")

            if farmInCustomPosToggle.value and customPositions[customPosDropdown.value] then
                if oldBeforeEventCFrame then SetBeforeEventCFrame(oldBeforeEventCFrame) end

                AddEvent(customPosDropdown.value, "CustomPosFarm", customPositions[customPosDropdown.value], 998)
            end
        end

        customPosDropdown.changed:Connect(FarmInCustomPos)
        farmInCustomPosToggle.changed:Connect(FarmInCustomPos)
    end

    do -- Don't sell all if crates are found
        local crateItemQuantity = 0

        local function ItemAdded(item)
            if item.Name:find("Crate") and not item.Name:find("Skin") then
                crateItemQuantity += 1
                if crateItemQuantity > 0 then
                    hasCratesInInventory = true
                end
            end
        end
        
        local function ItemRemoving(item)
            if item.Name:find("Crate") and not item.Name:find("Skin") then
                crateItemQuantity -= 1
                if crateItemQuantity == 0 then
                    hasCratesInInventory = false
                end
            end
        end

        for _, item in playerStats.Inventory:getChildren() do
            task.spawn(ItemAdded, item)
        end
        playerStats.Inventory.ChildAdded:Connect(ItemAdded)
        playerStats.Inventory.ChildAdded:Connect(ItemRemoving)
    end
    
    do -- Auto Totem
        local autoTotemEnabled = features["misc/auto_totem/enabled"]
        local totemsDropdown = features["misc/auto_totem/totems"]

        local function UseTotems()
            if autoTotemEnabled.value then
                if not character then characterAdded:Wait() end

                local auroraTotem = HasItem("Aurora Totem")
                local sundialTotem = HasItem("Sundial Totem")

                ItemProcessedWait()
                StartItemProcess()

                if worldData.cycle.Value == "Night" and auroraTotem and worldData.weather.Value ~= "Aurora_Borealis" then
                    humanoid:EquipTool(auroraTotem)
                    task.wait(0.01)
                    auroraTotem:Activate()
                    task.wait(4)
                elseif worldData.cycle.Value == "Day" and sundialTotem and worldData.weather.Value ~= "Windy" then
                    humanoid:EquipTool(sundialTotem)
                    task.wait(0.01)
                    sundialTotem:Activate()
                    task.wait(4)
                end

                FinishItemProcess()
            end
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            backpack.ChildAdded:Connect(UseTotems)
        end

        backpackAdded:Connect(function(backpack)
            backpack.ChildAdded:Connect(UseTotems)
        end)

        worldData.weather:GetPropertyChangedSignal("Value"):Connect(UseTotems)
        worldData.cycle:GetPropertyChangedSignal("Value"):Connect(UseTotems)
        autoTotemEnabled.changed:Connect(UseTotems)
        totemsDropdown.changed:Connect(UseTotems)
    end
end)()

-- // Finish
if readfile and isfile then
	makefolder("kiciahook")
	makefolder(HOME_DIR)
	makefolder(HOME_DIR .. "/configs")
	makefolder(HOME_DIR .. "/other")

	if isfile(HOME_DIR .. "/other/autoload.txt") then
		local configName = readfile(HOME_DIR .. "/other/autoload.txt")
		local configPath = HOME_DIR .. "/configs/" .. configName
		if configName ~= "" and isfile(configPath) then
			base:decodeJSON(readfile(configPath))
		end
	end
end

base:Finish()
