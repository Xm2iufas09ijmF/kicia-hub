local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local GuiService = cloneref(game:GetService("GuiService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local Trove = (function()
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

	newToggle: (self: UISection, flag: string, dontSave: boolean) -> UIToggle,
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
		label.Font = Enum.Font.SourceSans
		label.TextSize = 15
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
		title.Font = Enum.Font.SourceSans
		title.Position = UDim2.new(0, 4, 0, 4)
		title.Size = UDim2.new(1, -8, 0, 11)
		title.ZIndex = 2
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextStrokeTransparency = 0
		title.TextSize = 15
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
		self.instances.container.Size = UDim2.new(0, self.feature.instances.outline.AbsoluteSize.X, 0, math.min(6, #self.feature.options) * 17 + 1)
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
		label.Font = Enum.Font.SourceSans
		label.TextSize = 15
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

		trove:Connect(outline.MouseButton1Click, function(input: InputObject)
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
		button.Font = Enum.Font.SourceSans
		button.TextSize = 15
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
        -- ui size
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
		title.Font = Enum.Font.SourceSans
		title.TextSize = 15
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
			open.TextSize = 15
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

				--> ui size: 500, 350
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

        if not status then
            warn(err)
        end

        return status, err
    end

	function UIBase.Finish(self: UIBase)
		setthreadidentity(8)
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
		button.Font = Enum.Font.SourceSans
		button.TextSize = 15
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
	function UIToggle.new(parent: UISection, flag: string, dontSave: boolean)
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
        self.dontSave = dontSave

		self.base = base

		parent.instances.container.Size += UDim2.new(0 , 0, 0, 19)
		return UIToggle.into((self :: any) :: UIToggle, parent, base, flag)
	end

	function UISection.newToggle(self: UISection, flag: string, dontSave: boolean) : UIToggle
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
		label.Font = Enum.Font.SourceSans
		label.TextSize = 15
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
		label.Font = Enum.Font.SourceSans
		label.TextSize = 15
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
		plus.Font = Enum.Font.SourceSans
		plus.TextSize = 15
		plus.Position = UDim2.new(1, -13, 0, 0)
		plus.TextStrokeTransparency = 0
		plus.TextColor3 = Color3.fromRGB(255, 255, 255)
		plus.Parent = container
		self.instances.plus = plus

		local minus: TextButton = Instance.new("TextButton")
		minus.Text = "-"
		minus.BackgroundTransparency = 1
		minus.Size = UDim2.new(0, 11, 0, 11)
		minus.Font = Enum.Font.SourceSans
		minus.TextSize = 15
		minus.Position = UDim2.new(1, -26, 0, 0)
		minus.TextStrokeTransparency = 0
		minus.TextColor3 = Color3.fromRGB(255, 255, 255)
		minus.Parent = container
		self.instances.minus = minus

		local value: TextLabel = Instance.new("TextLabel")
		value.Font = Enum.Font.SourceSans
		value.TextSize = 15
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

		self.options = newOptions
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
		value.Font = Enum.Font.SourceSans
		value.TextSize = 15
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
		open.Font = Enum.Font.SourceSans
		open.TextSize = 15
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
			task.defer(function()
                self:setOptions(self.optionsCallback())
                self:set(prev)
            end)
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
		button.Font = Enum.Font.SourceSans
		button.TextSize = 15
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
		button.Font = Enum.Font.SourceSans
		button.TextSize = 15
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
		textbox.Font = Enum.Font.SourceSans
		textbox.TextSize = 15
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

		self._trove:Connect(textbox.FocusLost, function()
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
		label.Font = Enum.Font.SourceSans
		label.TextSize = 15
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

return UIBase
