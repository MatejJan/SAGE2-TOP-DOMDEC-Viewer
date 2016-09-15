maxStates = 2

class TopViewer.SaveState
  @findStateForName: (states, name) ->
    firstFreeIndex = 0

    # See if any of the states matches the one we're searching for.
    for i in [0...maxStates]
      return states[i].state if states[i].name is name

      # If there is no name at this index it is a free state that we can use.
      break unless states[i].name

      # The state is already used, let's see if next one matches or is free.
      firstFreeIndex++

    # We don't have the state with this name yet so add it to first free index, but we can only hold up to max states.
    return null unless firstFreeIndex < maxStates

    # Claim this state for the given name.
    states[firstFreeIndex].name = name

    # Return the associated state.
    states[firstFreeIndex].state
