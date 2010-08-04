#START:before
def find_by_sql(sql)
  if model_cache.enabled? && cachable = model_cache.parse_sql(sanitize_sql(sql))
    if cachable[:column] == "id"
      return model_cache.fetch(cachable[:value]) { super(sql) }
    else
      if id = model_cache.read_lookup_id(cachable[:column], cachable[:value])
        return [find(id)]
      else
        objects = super(sql)
        # What if record doesn't exist? Well, we can't cache that since that introduces a dependency on all records.
        id = objects.first.try(:id)
        model_cache.store_id_lookup(cachable[:column], cachable[:value], id) if id && objects.size == 1
        return objects
      end
    end
  else
    return super(sql)
  end
end
#END:before

#START:after
def find_by_sql(sql)
  finder = CachableModel::Finder.new(self, sanitize_sql(sql))
  if finder.is_cached?
    finder.cached_objects
  else
    objects = super(sql)
    finder.store_in_cache(objects) if finder.can_cache?(objects)
    objects
  end
end
#END:after
