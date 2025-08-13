//
//  SecondAgent.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 13.08.2025.
//

import Foundation

class SecondAgent: Agent {
    static let name = "Второй агент"
    
    static var finishedTag = "#Agent_2_finished"
    
    static let systemMessage = """
                            Ты эксперт в проверке ТЗ!
                            
                            Проверь ТЗ для приложения на предмет существует ли такая платформа!
                            Напиши "ТЗ корректно", если ошибок не нашел!
                            Если нашлись ошибки укажи на них!

                            В конце напиши \(finishedTag)
"""
}
