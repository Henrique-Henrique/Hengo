@tool
class_name HenSearch extends RefCounted

# optimized scoring function for fuzzy search
static func score_only(query_lower: String, text_lower: String) -> int:
	var q_len = query_lower.length()
	var t_len = text_lower.length()
	
	if q_len == 0:
		return 0
	
	# exact match
	if t_len == q_len and text_lower == query_lower:
		return 10000
	
	# starts with query
	if text_lower.begins_with(query_lower):
		if t_len == q_len:
			return 10000
		elif text_lower[q_len] == '_':
			return 5000 # complete word at start
		else:
			return 4000
	
	# contains query as substring
	var pos = text_lower.find(query_lower)
	if pos != -1:
		var before_sep = (pos == 0 or text_lower[pos - 1] == '_')
		var after_sep = (pos + q_len >= t_len or text_lower[pos + q_len] == '_')
		
		if before_sep and after_sep:
			return 3000 if pos == 0 else 2500 # complete word
		else:
			return 2000 if before_sep else 1500 # partial match
	
	# multiple words (e.g., "get position")
	if " " in query_lower:
		var words = query_lower.split(" ", false)
		var total = 0
		var positions = []
		
		for word in words:
			var word_pos = text_lower.find(word)
			if word_pos == -1:
				return 0
			positions.append(word_pos)
			total += 150
		
		# check if query matches text when removing spaces/underscores
		var query_no_space = query_lower.replace(" ", "")
		var text_no_underscore = text_lower.replace("_", "")
		
		if query_no_space == text_no_underscore:
			return 9500 # near-exact match
		
		var proximity_bonus = 0
		
		# bonus for starting with first word
		if positions[0] == 0:
			proximity_bonus += 3000
			
			# extra bonus if ends exactly after last word
			var last_word_idx = words.size() - 1
			var last_word = words[last_word_idx]
			var last_pos = positions[last_word_idx]
			var end_pos = last_pos + last_word.length()
			
			if end_pos == t_len:
				proximity_bonus += 2000 # ends exactly
			elif end_pos < t_len and text_lower[end_pos] == '_':
				proximity_bonus += 500 # continues with underscore
				
		elif positions[0] > 0 and text_lower[positions[0] - 1] == '_':
			proximity_bonus += 1500
		
		# check if words are in order
		var in_order = true
		for i in range(positions.size() - 1):
			if positions[i] >= positions[i + 1]:
				in_order = false
				break
		
		if in_order:
			proximity_bonus += 1000
			
			# bonus based on word proximity
			var total_distance = 0
			for i in range(positions.size() - 1):
				var distance = positions[i + 1] - positions[i] - words[i].length()
				total_distance += distance
			
			var avg_distance = total_distance / float(positions.size() - 1) if positions.size() > 1 else 0
			if avg_distance <= 1:
				proximity_bonus += 2000 # consecutive words
			elif avg_distance <= 5:
				proximity_bonus += 1000
			elif avg_distance <= 10:
				proximity_bonus += 500
			else:
				proximity_bonus += 100
		
		return total + 500 + proximity_bonus
	
	# search in underscore-separated parts
	if "_" in text_lower:
		var parts = text_lower.split("_", false)
		var best_score = 0
		
		for part in parts:
			if part == query_lower:
				best_score = max(best_score, 800)
			elif part.begins_with(query_lower):
				best_score = max(best_score, 400)
			elif query_lower in part:
				best_score = max(best_score, 200)
		
		return best_score
	
	return 0