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

# HTTP Actions
POST_ACTION = 'post'
PUT_ACTION = 'put'
GET_ACTION = 'get'
DELETE_ACTION = 'delete'

# HTTP Content-type
JSON_TYPE = 'application/json'
XML_TYPE = 'application/xml'

# Assembla variables
STATUS_A_FAZER = 24472231
SUSTENTACAO = 12627341
EDMILSON_USER_ID = 'dxi_DqEjSr6l_cacwqjQXA'

uncamelize = (str) ->
  str
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\b([A-Z]+)([A-Z])([a-z])/, '$1 $2$3')
    .replace(/^./,  (str) -> str.toUpperCase())

find_or_create_ticket = (msg, cb) ->
  msg.robot.assembla.api_call msg, "spaces/zg-devops/tickets?per_page=50&sort_order=desc&sort_by=created_on", (data) ->
    tickets = data.filter (t) ->
      (t.summary.toLowerCase().indexOf('subir versão corretiva') > -1) and
      (new Date().getDate() == new Date(t.created_on).getDate()) and
      (t.status == 'Para Fazer')

    ticket = tickets[0]

    if tickets.length > 1
      msg.send "Foram encontrados mas de um ticket de subida de versão hoje, usando o ##{ticket.number}"

    if ticket == undefined
      create_new_ticket msg, (new_ticket) -> cb(new_ticket)
    else
      cb(ticket)

create_new_ticket = (msg, cb) ->
  now = (new Date().toLocaleString('pt-BR').split(' '))[0]
  body = JSON.stringify({ticket: {summary: 'Subir versão corretiva '.concat(now), status_id: STATUS_A_FAZER, milestone_id: SUSTENTACAO, assigned_to_id: EDMILSON_USER_ID}})

  msg.robot.assembla.api_call msg, "spaces/zg-devops/tickets", (res, err, reso) ->
    if err
      console.error(err)
      robot.messageRoom "devops", "Erro ao cadastrar novo ticket #{body}: #{JSON.stringify(res)}"
      msg.send "Oops, aconteceu um erro ao cadastrar um novo ticket, peça ajuda aos devops ou faça na mão mesmo"
    else
      msg.send "Novo ticket adicionado com sucesso: https://app.assembla.com/spaces/zg-devops/tickets/#{res.number}/details"
      cb(res)
  , '', POST_ACTION, body, JSON_TYPE


module.exports = (robot) ->
  robot.messageRoom 'devops', "@here nova versão do zgbot acabou de subir"

  versao_rgx = /versao(\w*)\.add\(\s*['"]([^']*)['"]\s*,\s*['"]([^']*)['"]\s*(?:,\s*['"]([^']*)['"])?\s*\)/ig

  robot.hear versao_rgx, (msg) ->
    matches = versao_rgx.exec(msg.match[0])

    horario = uncamelize(matches[1].trim())
    projeto = matches[2].trim()
    versao = matches[3].trim()
    ambientes = matches[4]?.trim() or 'todos'

    ticket = find_or_create_ticket msg, (ticket) ->
      description = ticket.description or ''

      if description.indexOf(projeto) > -1
        msg.send "Projeto já encontrando na lista, para adicioná-lo novamente remova do ticket atual: https://app.assembla.com/spaces/zg-devops/tickets/#{ticket.number}/details"
        msg.send 'Ou implemente o bot pra descobrir duplicatas e resolver sozinho por horário :mauro:'
      else
        corpo = JSON.stringify({ticket: {description: "#{description?.trim() or ''}\n\n#{if horario then "> Versão de #{horario}\n" else ""}Serviço: #{projeto}\nAmbiente: #{ambientes}\nBranch: #{versao}"}})
        robot.assembla.api_call msg, "spaces/zg-devops/tickets/#{ticket.number}", (res, err, reso) ->
          if err
            console.error(err)
            robot.messageRoom "devops", "Erro ao cadastrar nova versão #{corpo} no ticket ##{ticket.number}: #{JSON.stringify(res)}"
            msg.send "Oops, aconteceu um erro ao cadastrar nova versão, peça ajuda aos devops ou faça na mão mesmo"
          else
            msg.send "Nova versão adicionada ao ticket ##{ticket.number} com sucesso"
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
