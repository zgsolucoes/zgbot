# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
#
uncamelize = (str) ->
  str
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\b([A-Z]+)([A-Z])([a-z])/, '$1 $2$3')
    .replace(/^./,  (str) -> str.toUpperCase())
    .replace(/[Dd]e\s*/, '')

find_or_create_ticket = (msg, cb) ->
  msg.robot.assembla.api_call msg, "spaces/zg-devops/tickets?per_page=50&sort_order=desc&sort_by=created_on", (data) ->
    tickets = data.filter((t) -> (t.summary.toLowerCase().indexOf('subir versão corretiva') > -1) and (new Date().getDate() == new Date(t.created_on).getDate()))
    ticket = tickets[0]

    if tickets.length > 0
      msg.send "Foram encontrados mas de um ticket de subida de versão hoje, usando o ##{ticket.number}"

    if ticket == undefined
      # TODO: criar ticket quando não houver
      msg.send 'Parece que não foi criado nenhum ticket para a versão corretiva de hoje, vá lá crie um com o nome "Subir versão corretiva" e reenvie a mensagem'
    else
      cb(ticket)

module.exports = (robot) ->
  versao_rgx = /versao(\w*)\.add\(\s*['"]([^']*)['"]\s*,\s*['"]([^']*)['"]\s*(?:,\s*['"]([^']*)['"])?\s*\)/ig
  robot.hear versao_rgx, (msg) ->
    matches = versao_rgx.exec(msg.match[0])

    horario = uncamelize(matches[1].trim())
    projeto = matches[2].trim()
    versao = matches[3].trim()
    ambientes = matches[4]?.trim() or 'todos'

    ticket = find_or_create_ticket msg, (ticket) ->
      description = ticket.description

      if description.indexOf(projeto) > -1
        msg.send "Projeto já encontrando na lista, para adicioná-lo novamente remova do ticket atual: https://app.assembla.com/spaces/zg-devops/tickets/#{ticket.number}/details"
        msg.send 'Ou implemente o bot pra descobrir duplicatas e resolver sozinho por horário :mauro:'
      else
        corpo = JSON.stringify({ ticket: { description: "#{description}\nServiço: #{projeto}\nAmbiente: #{ambientes}\nBranch: #{versao}" }})
        console.log(corpo)
        robot.assembla.api_call msg, "spaces/zg-devops/tickets/#{ticket.number}", (res) ->
          msg.send "Nova versão adicionada ao ticket com sucesso"
        , '', 'put', corpo, 'application/json'


  # robot.hear /badger/i, (res) ->
  #   res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
