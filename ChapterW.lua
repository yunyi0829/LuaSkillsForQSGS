--[[
	代码速查手册（W区）
	技能索引：
		完杀、危殆、帷幕、围堰、伪帝、温酒、无谋、无前、无双、无言、无言、武魂、武继、五灵、武圣、武神
]]--
--[[
	技能名：完杀（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】。
	状态：验证通过
]]--
LuaWansha = sgs.CreateTriggerSkill{
	name = "LuaWansha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if current:isAlive() then
			if current:hasSkill(self:objectName()) then
				local dying = data:toDying()
				local victim = dying.who
				local seat = player:getSeat()
				if current:getSeat() ~= seat then
					return victim:getSeat() ~= seat
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：危殆（主公技）
	相关武将：智·孙策
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止 
	状态：验证通过
]]--
LuaXWeidaiCard = sgs.CreateSkillCard{
	name = "LuaXWeidaiCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		if not source:hasFlag("drank") then
			if source:hasLordSkill("LuaXWeidai") then
				local players = room:getAlivePlayers()
				for _,liege in sgs.qlist(players) do
					if liege:getKingdom() == "wu" then
						if source:getHp() <= 0 or not source:hasUsed("Analeptic") then
							local tohelp = sgs.QVariant()
							tohelp:setValue(source)
							local prompt = string.format("@weidai-analeptic:%s", source:objectName())
							local analeptic = room:askForCard(liege, ".|spade|2~9|hand", prompt, tohelp, sgs.CardResponsed, source)
							if analeptic then
								local suit = analeptic:getSuit()
								local point = analeptic:getNumber()
								local ana = sgs.Sanguosha:cloneCard("analeptic", suit, point)
								ana:setSkillName("LuaXWeidai")
								local use = sgs.CardUseStruct()
								use.card = ana
								use.from = source
								use.to:append(use.from)
								room:useCard(use)
								if source:getHp() > 0 then
									break
								end
							end
						end
					end
				end
			end
		end
	end
}
LuaXWeidaiVS = sgs.CreateViewAsSkill{
	name = "LuaXWeidai$", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXWeidaiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:hasLordSkill("LuaXWeidai") then
			if not player:hasUsed("Analeptic") then
				return not player:hasUsed("#LuaXWeidaiCard")
			end
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXWeidai"
	end
}
LuaXWeidai = sgs.CreateTriggerSkill{
	name = "LuaXWeidai$",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Dying},  
	view_as_skill = LuaXWeidaiVS, 
	on_trigger = function(self, event, player, data) 
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() then
			local room = player:getRoom()
			room:askForUseCard(player, "@@LuaXWeidai", "@weidai")
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasLordSkill("LuaXWeidai")
		end
		return false
	end
}
--[[
	技能名：帷幕（锁定技）
	相关武将：林·贾诩、SP·贾诩
	描述：你不能被选择为黑色锦囊牌的目标。
	状态：验证通过
]]--
LuaWeimu = sgs.CreateProhibitSkill{
	name = "LuaWeimu", 
	is_prohibited = function(self, from, to, card)
		if card:isKindOf("TrickCard") then
			if card:isBlack() then
				local name = card:getSkillName()
				return name ~= "guhuo"
			end
		end
	end
}
--[[
	技能名：围堰
	相关武将：倚天·陆抗
	描述：你可以将你的摸牌阶段当作出牌阶段，出牌阶段当作摸牌阶段执行 
	状态：验证通过
]]--
LuaXLukangWeiyan = sgs.CreateTriggerSkill{
	name = "LuaXLukangWeiyan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data) 
		local change = data:toPhaseChange()
		local nextphase = change.to
		if nextphase == sgs.Player_Draw then
			if not player:isSkipped(sgs.Player_Draw) then
				if player:askForSkillInvoke("LuaXLukangWeiyan", sgs.QVariant("draw2play")) then
					change.to = sgs.Player_Play
					data:setValue(change)
				end
			end
		elseif nextphase == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if player:askForSkillInvoke("LuaXLukangWeiyan", sgs.QVariant("play2draw")) then
					change.to = sgs.Player_Draw
					data:setValue(change)
				end
			end
		end
		return false
	end
}
--[[
	技能名：伪帝（锁定技）
	相关武将：SP·袁术
	描述：你拥有当前主公的主公技。
	状态：验证失败
]]--
--[[
	技能名：温酒（锁定技）
	相关武将：智·华雄
	描述：你使用黑色的【杀】造成的伤害+1，你无法闪避红色的【杀】 
	状态：验证通过
]]--
LuaXWenjiu = sgs.CreateTriggerSkill{
	name = "LuaXWenjiu",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused, sgs.SlashProceed},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local hua = room:findPlayerBySkillName(self:objectName())
		if hua then
			if event == sgs.SlashProceed then
				local effect = data:toSlashEffect()
				if effect.to:objectName() == hua:objectName() then
					if effect.slash:isRed() then
						room:slashResult(effect, nil)
						return true
					end
				end
			elseif event == sgs.DamageCaused then
				local damage = data:toDamage()
				local reason = damage.card
				local source = damage.from
				if reason and source then
					if source:objectName() == hua:objectName() then
						if reason:isKindOf("Slash") then
							if reason:isBlack() then
								local count = damage.damage
								damage.damage = count + 1
								data:setValue(damage)
							end
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：无谋（锁定技）
	相关武将：神·吕布
	描述：当你使用一张非延时类锦囊牌选择目标后，你须弃1枚“暴怒”标记或失去1点体力。
	状态：验证通过
]]--
LuaWumou = sgs.CreateTriggerSkill{
	name = "LuaWumou",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed, sgs.CardResponsed},
	on_trigger = function(self, event, player, data)
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponsed then
			local resp = data:toResponsed()
			card = resp.m_card
		end
		local room = player:getRoom()
		if card:isNDTrick() then
			local num = player:getMark("@wrath")
			if num >= 1 then
				if room:askForChoice(player, self:objectName(), "discard+losehp") == "discard" then
					player:loseMark("@wrath")
				else
					room:loseHp(player)
				end
			else
				room:loseHp(player)
			end
		end
		return false
	end
}
--[[
	技能名：无前
	相关武将：神·吕布
	描述：出牌阶段，你可以弃2枚“暴怒”标记并选择一名其他角色，该角色的防具无效且你获得技能“无双”，直到回合结束。
	状态：验证通过
]]--
LuaWuqianCard = sgs.CreateSkillCard{
	name = "LuaWuqianCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room = target:getRoom()
		local source = effect.from
		source:loseMark("@wrath", 2)
		room:acquireSkill(source, "wushuang", false)
		room:setPlayerFlag(target,"wuqian")
	end
}
LuaWuqian = sgs.CreateViewAsSkill{
	name = "LuaWuqian",
	n = 0, 
	view_as = function(self, cards)
		return LuaWuqianCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@wrath") >= 2
	end
}
LuaWuqianClear = sgs.CreateTriggerSkill{
	name = "#LuaWuqianClear", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.Death}, 
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart or event == sgs.Death then
			if player:hasSkill(self:objectName()) then
				if event == sgs.Death or player:getPhase() == sgs.Player_NotActive then
					local room = player:getRoom()
					local list = room:getAllPlayers()
					for _,p in sgs.qlist(list) do
						if p:hasFlag("wuqian") then
							room:setPlayerFlag(p, "-wuqian")
						end
					end
					if not player:hasInnateSkill("wushuang") then
						room:detachSkillFromPlayer(player, "wushuang")
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasSkill("LuaWuqian")
		end
		return false
	end
}
--[[
	技能名：无双（锁定技）
	相关武将：标准·吕布、SP·最强神话、SP·暴怒战神
	描述：当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。
	状态：验证通过
]]--
LuaWushuang = sgs.CreateTriggerSkill{
	name = "LuaWushuang", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed, sgs.SlashProceed},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") then
				if use.from:objectName() == player:objectName() then
					room:setCardFlag(card, "WushuangInvke")
				end
			elseif card:isKindOf("Duel") then
				room:setCardFlag(card, "WushuangInvke")
			end
		elseif event == sgs.SlashProceed then
			local effect = data:toSlashEffect()
			local dest = effect.to
			if effect.slash:hasFlag("WushuangInvke") then
				local slasher = player:objectName()
				local hint = string.format("@wushuang-jink-1:%s", slasher)
				local first_jink = room:askForCard(dest, "jink", hint, sgs.QVariant(), sgs.CardUsed, player)
				local second_jink = nil
				if first_jink then
					hint = string.format("@wushuang-jink-2:%s", slasher)
					second_jink = room:askForCard(dest, "jink", hint, sgs.QVariant(), sgs.CardUsed, player)
				end
				local jink = nil
				if first_jink and second_jink then
					jink = sgs.Sanguosha:cloneCard("Jink", sgs.Card_NoSuit, 0)
					jink:addSubcard(first_jink)
					jink:addSubcard(second_jink)
				end
				room:slashResult(effect, jink)
			end
			return true
		end
		return false
	end
}
--[[
	技能名：无言（锁定技）
	相关武将：一将成名·徐庶
	描述：你防止你造成或受到的任何锦囊牌的伤害。
	状态：验证通过
]]--
LuaWuyan = sgs.CreateTriggerSkill{
	name = "LuaWuyan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused, sgs.DamageInflicted}, 
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:getTypeId() == sgs.Card_Trick then
				if event == sgs.DamageInflicted then
					if player:hasSkill(self:objectName()) then
						return true
					end
				end
				if event == sgs.DamageCaused then
					local source = damage.from
					if source then
						if source:isAlive() then
							if source:hasSkill(self:objectName()) then
								return true
							end
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：无言（锁定技）
	相关武将：怀旧·徐庶
	描述：你使用的非延时类锦囊牌对其他角色无效；其他角色使用的非延时类锦囊牌对你无效。
	状态：验证通过
]]--
LuaNosWuyan = sgs.CreateTriggerSkill{
	name = "LuaNosWuyan", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardEffect, sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local source = effect.from
		local target = effect.to
		local card = effect.card
		if target and source then
			if target:objectName() ~= source:objectName() then
				if card:getTypeId() == sgs.Card_Trick then
					if source:hasSkill(self:objectName()) then
						return true
					end
					if target:hasSkill(self:objectName()) then
						return true
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--[[
	技能名：武魂（锁定技）
	相关武将：神·关羽
	描述：每当你受到1点伤害后，伤害来源获得一枚“梦魇”标记；你死亡时，令拥有最多该标记的一名其他角色进行一次判定，若判定结果不为【桃】或【桃园结义】，该角色死亡。
	状态：验证通过
]]--
LuaWuhun = sgs.CreateTriggerSkill{
	name = "LuaWuhun", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged, sgs.EventLoseSkill}, 
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				local source = damage.from
				if source and source:objectName() ~= player:objectName() then
					source:gainMark("@nightmare", damage.damage)
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local room = player:getRoom()
				local list = room:getAllPlayers()
				for	_,p in sgs.qlist(list) do
					p:loseAllMarks("@nightmare")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
LuaWuhunRevenge = sgs.CreateTriggerSkill{
	name = "#LuaWuhunRevenge", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Death}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local ps = room:getOtherPlayers(player)
		local maxcount = 0
		for _,p in sgs.qlist(ps) do
			local count = p:getMark("@nightmare")
			maxcount = math.max(maxcount, count)
		end
		if maxcount > 0 then
			local foes = sgs.SPlayerList()
			for _,p in sgs.qlist(ps) do
				if p:getMark("@nightmare") == maxcount then
					foes:append(p)
				end
			end
			if foes:length() > 0 then
				local foe
				if foes:length() == 1 then
					foe = foes:at(0)
				else
					foe = room:askForPlayerChosen(player, foes, "LuaWuhun")
				end
				local judge = sgs.JudgeStruct()
				judge.pattern = sgs.QRegExp("(Peach|GodSalvation):(.*):(.*)")
				judge.good = true
				judge.negative = true
				judge.reason = "LuaWuhun"
				judge.who = foe
				judge.play_animation = true
				room:judge(judge)
				if judge:isBad() then
					room:killPlayer(foe)
				end
				local killers = room:getAllPlayers()
				for _,p in sgs.qlist(killers) do
					p:loseAllMarks("@nightmare")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasSkill("LuaWuhun")
		end
		return false
	end
}
--[[
	技能名：武继（觉醒技）
	相关武将：SP·关银屏
	描述：回合结束阶段开始时，若本回合你已造成3点或更多伤害，你须加1点体力上限并回复1点体力，然后失去技能“虎啸”。 
	状态：验证通过
]]--
LuaWujiCount = sgs.CreateTriggerSkill{
	name = "#LuaWujiCount", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DamageDone, sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:isAlive() then
				if source:objectName() == room:getCurrent():objectName() then
					if source:getMark("LuaWuji") == 0 then
						local count = source:getMark("LuaWujiDamage")
						room:setPlayerMark(source, "LuaWujiDamage", count+damage.damage)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("LuaWujiDamage") > 0 then
					room:setPlayerMark(player, "LuaWujiDamage", 0)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
LuaWuji = sgs.CreateTriggerSkill{
	name = "LuaWuji",  
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:addMark("LuaWuji")
		player:gainMark("@waked")
		local maxhp = player:getMaxHp() + 1
		room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player, recover)
		room:detachSkillFromPlayer(player, "huxiao")
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Finish then
					if target:getMark("LuaWuji") == 0 then
						return target:getMark("LuaWujiDamage") >= 3
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：五灵
	相关武将：倚天·晋宣帝
	描述：回合开始阶段，你可选择一种五灵效果发动，该效果对场上所有角色生效
		该效果直到你的下回合开始为止，你选择的五灵效果不可与上回合重复
		[风]场上所有角色受到的火焰伤害+1
		[雷]场上所有角色受到的雷电伤害+1
		[水]场上所有角色使用桃时额外回复1点体力
		[火]场上所有角色受到的伤害均视为火焰伤害
		[土]场上所有角色每次受到的属性伤害至多为1 
	状态：验证通过
]]--
LuaXWulingExEffect = sgs.CreateTriggerSkill{
	name = "#LuaXWulingExEffect",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardEffected, sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local tag = room:getTag("wuling")
		if tag then
			local wuling = tag:toString()
			if event == sgs.CardEffected then
				if wuling == "water" then
					local effect = data:toCardEffect()
					local peach = effect.card
					if peach and peach:isKindOf("Peach") then
						local recover = sgs.RecoverStruct()
						recover.card = peach
						recover.who = effect.from
						room:recover(player, recover)
					end
				end
			elseif event == sgs.DamageInflicted then
				if wuling == "earth" then
					local damage = data:toDamage()
					if damage.nature ~= sgs.DamageStruct_Normal then				
						if damage.damage > 1 then
							damage.damage = 1
							data:setValue(damage)
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = -1
}
LuaXWulingEffect = sgs.CreateTriggerSkill{
	name = "#LuaXWulingEffect",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local tag = room:getTag("wuling")
		if tag then
			local wuling = tag:toString()
			local damage = data:toDamage()
			local nature = damage.nature
			local count = damage.damage
			local flag = not damage.chain and not damage.transfer
			if wuling == "wind" then
				if nature == sgs.DamageStruct_Fire then
					if flag then
						damage.damage = count + 1
						data:setValue(damage)
					end
				end
			elseif wuling == "thunder" then
				if nature == sgs.DamageStruct_Thunder then
					if flag then
						damage.damage = count + 1
						data:setValue(damage)
					end
				end
			elseif wuling == "fire" then
				if nature ~= sgs.DamageStruct_Fire then
					damage.nature = sgs.DamageStruct_Fire
					data:setValue(damage)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = 2
}
LuaXWuling = sgs.CreateTriggerSkill{
	name = "LuaXWuling",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local effects = {"wind", "thunder", "water", "fire", "earth"}
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local current = nil
			local tag = room:getTag("wuling")
			if tag then
				current = tag:toString()
			end
			local choices = ""
			for _,effect in pairs(effects) do
				if effect ~= current then
					choices = string.format("%s+%s", choices, effect)
				end
			end
			choices = string.sub(choices, 2)
			local choice = room:askForChoice(player, self:objectName(), choices)
			local mark = nil
			if current then
				mark = string.format("@%s", current)
				player:loseMark(mark)
			end
			mark = string.format("@%s", choice)
			player:gainMark(mark)
			room:setTag("wuling", sgs.QVariant(choice))
		end
		return false
	end
}
--[[
	技能名：武圣
	相关武将：标准·关羽、翼·关羽
	描述：你可以将一张红色牌当【杀】使用或打出。
	状态：验证通过
]]--
LuaWusheng = sgs.CreateViewAsSkill{
	name = "LuaWusheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isRed() then
			return false
		end
		local weapon = sgs.Self:getWeapon()
		if weapon then
			if to_select == weapon then
				if to_select:objectName() == "Crossbow" then
					return sgs.Self:canSlashWithoutCrossbow()
				end
			end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			slash:addSubcard(card:getId())
			slash:setSkillName(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}
--[[
	技能名：武神（锁定技）
	相关武将：神·关羽
	描述：你的红桃手牌均视为【杀】；你使用红桃【杀】时无距离限制。
	状态：0224验证通过
]]--
LuaWushen = sgs.CreateFilterSkill{
	name = "LuaWushen",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local id = to_select:getEffectiveId()
		local place = room:getCardPlace(id)
		if to_select:getSuit() == sgs.Card_Heart then
			return place == sgs.Player_PlaceHand
		end
		return false
	end, 
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
		slash:setSkillName(self:objectName())
		local id = card:getId()
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(slash)
		return vs_card
	end
}
LuaWushenTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaWushen-target",
	distance_limit_func = function(self, from, card)
        if from:hasSkill("LuaWushen") and card:getSuit() == sgs.Card_Heart then
            return 1000
        else
            return 0
		end
	end
}