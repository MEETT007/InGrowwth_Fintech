package com.ingrowwth.homeloan;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.scheduling.annotation.*;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@Component
@EnableScheduling
class LiveUpdates {
  final Map<SseEmitter, String> subscribers = new ConcurrentHashMap<>();

  SseEmitter connect(String user) {
    SseEmitter s = new SseEmitter(1800000L);
    subscribers.put(s, user);
    s.onCompletion(() -> subscribers.remove(s));
    s.onTimeout(() -> subscribers.remove(s));
    s.onError(e -> subscribers.remove(s));
    try {
      s.send(SseEmitter.event().name("ready").data(Map.of("connected", true)));
    } catch (Exception e) {
      subscribers.remove(s);
    }
    return s;
  }

  void publish(String borrower, String loanId) {
    subscribers.forEach(
        (s, u) -> {
          if (u.equals(borrower) || u.equals("OFFICER"))
            try {
              s.send(SseEmitter.event().name("case-update").data(Map.of("loanId", loanId)));
            } catch (Exception e) {
              subscribers.remove(s);
            }
        });
  }

  @Scheduled(fixedRate = 25000)
  void heartbeat() {
    subscribers.forEach(
        (s, u) -> {
          try {
            s.send(SseEmitter.event().comment("keepalive"));
          } catch (Exception e) {
            subscribers.remove(s);
          }
        });
  }
}
