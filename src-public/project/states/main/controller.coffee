angular.module 'NotSoShitty.settings'
.controller 'ProjectCtrl', (
  $scope
  $timeout
  $q
  boards
  TrelloClient
  localStorageService
  $mdToast
  Project
  user
) ->
  $scope.boards = boards
  if user.project?
    project = user.project
  else
    project = new Project()

  $scope.project = project

  fetchBoardData = (boardId) ->
    $q.all [
      # the the list of columns
      TrelloClient.get("/boards/#{boardId}/lists")
      .then (response) ->
        $scope.boardColumns = response.data
      .catch (err) ->
        $scope.project.boardId = null
        console.warn "Could not fetch Trello board with id #{boardId}"
        console.log err

      # get the list of users
      TrelloClient.get("/boards/#{boardId}/members?fields=avatarHash,fullName,initials,username")
      .then (response) ->
        $scope.boardMembers = response.data
      .catch (err) ->
        $scope.project.boardId = null
        console.warn "Could not fetch Trello board members"
        console.log err

      # find if there is already a project for this board
      # otherwise create one
      Project.get boardId
      .then (response) ->
        return response if response?

        console.log "No project with boardId #{boardId} found. Creating a new one"
        project = new Project()
        project.boardId = boardId
        project.team =
          rest: []
          dev: []
        project.save()
      .then (project) ->
        $scope.project = project
    ]


  if $scope.project.boardId?
    fetchBoardData $scope.project.boardId

  # Get board colums and members when board is set
  $scope.$watch 'project.boardId', (next, prev) ->
    return unless next? and next != prev
    fetchBoardData next
    $scope.save()

  $scope.$watch 'project.team', (next, prev) ->
    return unless next? and  not angular.equals next, prev
    $scope.save()
  , true

  $scope.clearTeam = ->
    $scope.project.team.rest = []
    $scope.project.team.dev = []
    $scope.save()
  #
  saveFeedback = $mdToast.simple()
    .hideDelay(1000)
    .position('top right')
    .content('Saved!')

  promise = null
  $scope.save = ->
    return unless $scope.project.boardId?

    # wait 2s before saving
    if promise?
      $timeout.cancel promise
    promise = $timeout ->
      $scope.project.save().then (p) ->
        user.project = p
        user.save().then ->
          $mdToast.show saveFeedback
    , 2000
  return