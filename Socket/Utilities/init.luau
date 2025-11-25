local utils = {}

utils.GetTableCount = function(t : {[any] : any}) : number
	local count = 0
	for _,v in t do
		count += 1
	end
	return count
end

return utils
