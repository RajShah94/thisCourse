define ["cs!utils/formatters"], (formatters) ->
    
    Backbone.Model.prototype.idAttribute = "_id"

    class BaseModel extends Backbone.Model

        url: => # TODO: test this, and make the api endpoint configurable
            if @apiCollection
                return "/api/" + @apiCollection + "/" + (@id or "")

        getDate = (attr) ->
            date = @get(attr)
            if not date
                return undefined
            else if date instanceof Array
                return (formatters.date_from_string(d) for d in date)
            else
                return formatters.date_from_string date
                
        save: =>
            @trigger("save", @)
            super

    class LazyModel extends BaseModel

        loaded: false
        loading: false

        constructor: ->
            @relations = @relations?() or @relations or {}
            for key,relation of @relations
                if not (relation.model or relation.collection)
                    throw "Error: All relations must specify either a model or a collection (key: '" + key + "')"
                relation.includeInJSON or= []
            super

        set: (attributes, options) ->
            idAttribute = Backbone.Model.prototype.idAttribute
            for key,opts of @relations
                opts.includeInJSON.push idAttribute
                if opts.collection # if it's a "one to many" relation
                    if key not of attributes then attributes[key] = [] # default to an empty collection
                    collection = attributes[key] = new opts.collection(attributes[key]) # turn array into collection
                    collection.includeInJSON = opts.includeInJSON
                    collection.url = (@url?() or @url) + key # TODO: do a better join? what if parent not saved yet?
                    for model in collection.models # add a parent link to each of the collection's models
                        model.parent = {model: @, key: key}
                        model.includeInJSON = opts.includeInJSON
                else if opts.model # if it's a "one to one" relation
                    if key not of attributes then attributes[key] = {} # default to an empty model
                    if _.isString(attributes[key]) # if just a string, assume it's an id and put it in an object
                        attributes[key] = {_id: attributes[key]}
                    if _.isObject(attributes[key]) # if it's an object (should be!), then turn it into a model
                        model = attributes[key] = new opts.model(attributes[key])
                        model.parent = {model: @, key: key} # add a parent link to the model
                        model.includeInJSON = opts.includeInJSON
                        model.url = (@url?() or @url) + key # TODO: do a better join? what if parent not saved yet?
            super attributes, options

        toJSON: ->
            attrs = super
            if @parent
                attrs.parent =
                    model: @parent.model.constructor.name
                    key: @parent.key
                if @parent.model.id
                    attrs.parent.id = @parent.model.id
            for key of attrs
                if key of @relations and @relations[key].includeInJSON!=true
                    attrs[key] = attrs[key].toJSON()
                    relation = @relations[key]
                    if relation.model
                        models = [attrs[key]]
                    else if relation.collection
                        models = attrs[key]
                    for model in models
                        for modelkey of model
                            if modelkey not in relation.includeInJSON
                                delete model[modelkey]
            return attrs

        save: (fields) =>
            console.log "Saving:", @toJSON(), "at", @url?() or @url
            super

    class BaseCollection extends Backbone.Collection

    class LazyCollection extends BaseCollection


    BaseModel: BaseModel
    LazyModel: LazyModel
    BaseCollection: BaseCollection
    LazyCollection: LazyCollection
