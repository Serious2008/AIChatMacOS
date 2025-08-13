//
//  FirstAgent.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 13.08.2025.
//

import Foundation

protocol Agent {
    static var name: String { get }
    static var systemMessage: String { get }
    static var finishedTag: String { get }
}

class FirstAgent: Agent {
    static let name = "Первый агент"
    
    static var finishedTag = "#Agent_1_finished"
    
    static let systemMessage = """
                            Ты эксперт в составлении ТЗ для разработки приложений!
                            Проведи короткий опрос пользователя состоящий из 3 вопросов.
                            
                            - Какое приложение вы хотите сделать
                            - Для какой платформы
                            - Основные функции

                            Вопросы задавай по одному, без рассуждений!
                            Не задавай уточняющие вопросы!

                            После сразу напиши короткое ТЗ для этого приложения!
                            В конце ТЗ добавь \(finishedTag)
"""
}
