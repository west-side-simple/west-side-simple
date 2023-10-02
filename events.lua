if TVSources_var then dofile(TVSources_var.TVSdir ..'/events.lua') end
---------------------------
--input
--m_simpleTV.Control.Reason              Error|EndReached|Stopped|Playing|Sleeping|addressready|Timeout|ScrambledOn|ScrambledOff|Exiting
--m_simpleTV.Control.CurrentAddress      Address from database
--m_simpleTV.Control.RealAddress		 Real Address

--output
--m_simpleTV.Control.CurrentAddress      Address from database
--m_simpleTV.Control.Action              dodefault|repeat|stop|nothing

--m_simpleTV.Control.Reason=Sleeping - comp going to sleep, all other fields are undefined
--m_simpleTV.Control.Reason=Exiting  - program is terminated, all other fields are undefined

--m_simpleTV.OSD.ShowMessage('r - ' .. m_simpleTV.Control.Reason .. ',addr= ' .. m_simpleTV.Control.CurrentAddress .. ',radr=' .. m_simpleTV.Control.RealAddress ,255,1)
--debug_in_file('r - ' .. m_simpleTV.Control.Reason .. ', addr= ' .. m_simpleTV.Control.CurrentAddress .. ', radr=' .. m_simpleTV.Control.RealAddress .. '\n')
--debug_in_file('mode:' .. m_simpleTV.Control.GetMode() ..  ',reason:' .. m_simpleTV.Control.Reason .. ', addr:' .. m_simpleTV.Control.CurrentAddress .. ', radr:' .. m_simpleTV.Control.RealAddress .. '\n')

--m_simpleTV.Control.EventPlayingInterval=1000
--m_simpleTV.Control.EventTimeOutInterval=1000
ExecuteFilesByReason('events')
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if m_simpleTV.Control.Reason == 'Playing' then
	local t = m_simpleTV.Control.GetCurrentChannelInfo()
	if t.Id == nil or t.Id == 268435455 then return end
	local t1 = m_simpleTV.Database.GetTable('SELECT * FROM Channels WHERE Id==' .. t.Id .. ';')
	if t1[1].TypeMedia ~= 0 then return end
	if t1[1].EpgId == nil or t1[1].EpgId == '' then
			m_simpleTV.Database.ExecuteSql('UPDATE Channels SET EpgId="NOEPG by WS" WHERE ((Channels.Id=' .. t1[1].Id .. '));')
			m_simpleTV.PlayList.Refresh()
	else
			local start_EPG = os.time() - (os.date("%H",os.time())*60*60 + os.date("%M",os.time())*60 + os.date("%S",os.time())) - os.date("%w",os.time())*24*60*60 - 6*24*60*60
			local EPG = {
			{0,1,"ночное вещание"},
			{1,2,"ночное вещание"},
			{2,3,"ночное вещание"},
			{3,4,"ночное вещание"},
			{4,5,"ночное вещание"},
			{5,6,"ночное вещание"},
			{6,7,"утреннее вещание"},
			{7,8,"утреннее вещание"},
			{8,9,"утреннее вещание"},
			{9,10,"утреннее вещание"},
			{10,11,"утреннее вещание"},
			{11,12,"утреннее вещание"},
			{12,13,"дневное вещание"},
			{13,14,"дневное вещание"},
			{14,15,"дневное вещание"},
			{15,16,"дневное вещание"},
			{16,17,"дневное вещание"},
			{17,18,"дневное вещание"},
			{18,19,"вечернее вещание"},
			{19,20,"вечернее вещание"},
			{20,21,"вечернее вещание"},
			{21,22,"вечернее вещание"},
			{22,23,"вечернее вещание"},
			{23,24,"вечернее вещание"},
			}
			local k = 0
			m_simpleTV.Database.ExecuteSql('START TRANSACTION;/*ChProg*/')
			for i = 1,14 do
				local start_time = tonumber(start_EPG) + (i - 1)*24*60*60
				for j = 1,24 do
					local StartPr = tonumber(start_time) + tonumber(EPG[j][1])*60*60
					local EndPr = tonumber(start_time) + tonumber(EPG[j][2])*60*60
					StartPr = os.date('%Y-%m-%d %X', StartPr)
					EndPr = os.date('%Y-%m-%d %X', EndPr)
					local sql1 = 'SELECT * FROM ChProg WHERE IdChannel=="' .. t1[1].EpgId .. '"' .. ' AND StartPr <= "' .. StartPr .. '" AND EndPr > "' .. StartPr .. '"'
					local sql2 = 'SELECT * FROM ChProg WHERE IdChannel=="' .. t1[1].EpgId .. '"' .. ' AND StartPr <= "' .. EndPr .. '" AND EndPr > "' .. EndPr .. '"'
					local epg1 = m_simpleTV.Database.GetTable(sql1)
					local epg2 = m_simpleTV.Database.GetTable(sql2)
					if epg1 == nil
						or epg1 and epg1[1] == nil
						or epg1 and epg1[1] and epg1[1].Title == nil
						or epg1 and epg1[1] and epg1[1].Title and epg1[1].Title == ''
						or epg2 == nil
						or epg2 and epg2[1] == nil
						or epg2 and epg2[1] and epg2[1].Title == nil
						or epg2 and epg2[1] and epg2[1].Title and epg2[1].Title == ''
					then
						if epg1 and epg1[1] and epg1[1].Title and epg1[1].Title ~= '' then StartPr = epg1[1].EndPr end
						if epg2 and epg2[1] and epg2[1].Title and epg2[1].Title ~= '' then EndPr = epg2[1].StartPr end
						k = k + 1
						local Title = EPG[j][3]
						m_simpleTV.Database.ExecuteSql('INSERT INTO ChProg (IdChannel, StartPr, EndPr, Title, Desc, HaveDesc, Category, IconUrl) VALUES ("' .. t1[1].EpgId .. '","' .. StartPr .. '","' .. EndPr .. '","' .. Title .. '","","0","NOEPG by WS","");', true)
					end
					j = j + 1
				end
				i = i + 1
			end
			m_simpleTV.Database.ExecuteSql('COMMIT;/*ChProg*/')
			if k > 0 then
				m_simpleTV.EPG.Refresh()
			end
		end
	end
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
