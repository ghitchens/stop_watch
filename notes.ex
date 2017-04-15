# subscriber api

  subscribe()
  handle_notification(...)

# source API (not including state)

  register_source(registry, source, initial_event_data)  # sends registration info
  deregister_source(registry, source, final_notification_data)

  inform(notification_data)
