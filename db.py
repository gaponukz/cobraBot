import json

class UsersList(list):
    def append(self, __object) -> None:
        with open('signed_users.json', 'w', encoding='utf-8') as out:
            super().append(__object)
            json.dump(self, out, indent=4)
        
    def remove(self, __object) -> None:
        with open('signed_users.json', 'w', encoding='utf-8') as out:
            super().remove(__object)
            json.dump(self, out, indent=4)
    
    def find_user(self, _id: int) -> dict | None:
        filter_users = [user for user in self if user['id'] == _id]

        return filter_users[0] if filter_users else None
    
    def edit_user(self, user_id: int, **kwargs):
        user = self.find_user(user_id)
        self.remove(user)
        user[list(kwargs)[0]] = kwargs[list(kwargs)[0]]
        self.append(user)

        return user
    
    @staticmethod
    def get_default_user(_id):
        return {"id": _id, "language": "en", "ref_id": None, "address": None}
