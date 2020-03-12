require "/scripts/util.lua"

kitmath = {}

function kitmath.set(value, nvalue)
  if type(value) == "table" then
    for k, v in ipairs(value) do
	  value[k] = nvalue
	end
  else
    value = nvalue
  end
  return value
end

function kitmath.multiply(value, modifier)
  if type(value) == "table" then
	for k, v in ipairs(value) do
	  value[k] = value[k] * modifier
	end
  else
    value = value * modifier
  end
  return value
end

function kitmath.divide(value, modifier)
  if type(value) == "table" then
	for k, v in ipairs(value) do
	  value[k] = value[k] / modifier
	end
  else
    value = value / modifier
  end
  return value
end

function kitmath.add(value, modifier)
  if type(value) == "table" then
	for k, v in ipairs(value) do
	  value[k] = value[k] + modifier
	end
  else
    value = value + modifier
  end
  return value
end

function kitmath.subtract(value, modifier)
  return kitmath.add(value, -1 * modifier)
end

function kitmath.exponentiate(value, modifier)
  if type(value) == "table" then
	for k, v in ipairs(value) do
	  value[k] = value[k] ^ modifier
	end
  else
    value = value ^ modifier
  end
  return value
end