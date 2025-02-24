# Godot Skeleton2D Helper

This is a tool that supports the creation of bone animations for Godot 4.3~.

Godot Engine Editor only addon.

[English README is here](#englishreadme)

---

Godot4.3〜4.4のボーンアニメーションの制作をサポートするツールです。

Godotのエディタアドオンとして使用します。

自分用に作成しているものです。機能は揃っていますがドキュメントが薄いです。

また、追加予定の機能もありますが

今後2Dメッシュをゲームで使用するプロジェクトを本格的にはじめたときに使用するので、その時に手入れをします。

---

![image](https://github.com/user-attachments/assets/32cd3b5f-e054-4da7-ae7a-d7e7d684ebac)

## 基本機能

- ボーンの作成・移動
- 割り当てるスプライトシート画像の登録・範囲の管理
- 画像のポリゴン割り
- アニメーション補助

いちおしはポリゴン割りです。

SpineやLive2DのようなメッシュアニメーションはGodotSkeleton2DとPolygon2Dのノードで一応できるのですが作成手順がとても面倒です。

このアドオンを使えばそのあたりの操作がやりやすくなります。

## 使い方

アドオンを有効にします。

2Dのシーンを開くと2Dキャンバスメインビューの下部にタブが出ています。

シーンにSkeleton2Dノードと、その子としてルートのBone2Dノードを追加します。

ボーンから追加するか、画像から登録するかはあなたのワークフローによります。

---

## 「ボーン」タブ

![image](https://github.com/user-attachments/assets/11c9e5b7-688b-4071-af66-0af077c21648)
ボーンの作成・移動を行います。

おそらく、ショートカットでの使用が多いです。
(X)のようになっているのがショートカットキーです。

現在は変更不可能です。(変更したいときは内部コードのどこかを変更してください)

### ゆる選択（X）
マウスカーソルの近くにあるボーンを選択します。

### ボーンの追加（Shift＋A）
「ボーンを押し出し」のように
選択中のボーンからマウスの位置へと子のBone2Dを作成します。

### ボーンの頭の移動（A）
ボーンの頭（Head）を移動します。頭のみが動きます。
マウスを移動させると移動したぶんだけ動きます。

### ボーンの先端の移動（Ctrl + Alt + A）
ボーンの先端（Tail）を移動します。先端のみが動きます。
マウスを移動させると移動したぶんだけ動きます。

---

Godotのボーンはなんか……1本余分に増やさないと動かない？
ふだんBlenderとか触ってると違和感があるけど2Dだとこんなもんなの？根っこ曲げるときとか……

---

## 「画像」タブ

![image](https://github.com/user-attachments/assets/89e97561-335f-4715-800b-e366dfad23a2)

画像ファイルを登録します。
画像ファイルは透明部分を矩形で分割して、範囲Regionをリストに登録します。

登録した画像の情報はルートディレクトリの"skeleton2dhelper_save.txt"に保存されています。

メッシュアニメにしたい場合はポリゴンの割りをします。

外周点の＋でおおまかに追加していきます。
囲ったあとにその外周点を点えんぴつマークみたいなボタンでこまかくして配置していきます。
移動は移動っぽいボタンを押すとマウスでクリックした近くの点を動かします。

近いものを選択するのでマウスのエイム力は必要ありません！

そのあとに内部点を追加していきます。やり方はおなじです。
内部点は青く表示されます

へんなとこにうったりポリゴンとしておかしくなると表示されませんが、点を移動して正常にもどすと直ります。

---

## 「アニメーション」タブ

![image](https://github.com/user-attachments/assets/1da4e899-0ba8-420b-a0b1-5caf6843d0bd)

ボーンアニメーション作成の補助をするときのタブです。

かなり作りかけです。

キー関連をもうちょっとなんとかする予定。

---

# EnglishREADME

# Godot Skeleton2D Helper

This is a tool that supports the creation of bone animations for Godot 4.3~.

Godot Engine Editor only addon.

I created it for my own project.

There are also features I plan to add,

I will use it when I start a project that uses 2D meshes in games in earnest, so I will update then.

---

![image](https://github.com/user-attachments/assets/161c4d09-ba20-4b99-94da-886476a92781)


## Features

- Add and moving bones
- Manage the sprite sheet images you use
- Create Polygon2D Mesh Vertexs. like Spine.
- Bone Animation insert key helper

Mesh animation like Spine or Live2D can be done with GodotSkeleton2D and Polygon2D nodes, but GodotEngine Editor's creation process is very tedious.

Using this add-on makes it easier to perform such operations.

## How to Use

Enable the add-on.

open 2D scene, this addon tab will appear at the bottom of the 2D Canvas main view.

Add a Skeleton2D node to the scene and a root Bone2D node as its child.

Whether you add from bones or register from images depends on your workflow.

---

## Bone Tab

![image](https://github.com/user-attachments/assets/6bbb6e1d-715a-4d98-abce-a838131600e2)

Add new bone and moves bones.

The key shortcut function is useful.

Currently, key assignments cannot be changed. (If you want to change them, change somewhere in the internal code.)

### Near Select（X）
Selects the bone closest to the mouse cursor.

### Add Bone（Shift＋A）
Like "Extrude Bone", it creates a child Bone2D from the selected bone to the mouse position.

### Move Bone Head（A）
Move the head of the bone. Only the head moves.
When you move the mouse, it moves the amount you move it.

### Move Bone tail（Ctrl + Alt + A）
Move the tail of the bone. Only the tail will move.
When you move the mouse, it will move the amount you move it.

---

## Image Tab

![image](https://github.com/user-attachments/assets/465efcac-7b2a-45ec-a6fd-40b1d5f69e90)

image file.

Divide the transparent parts of the image file into rectangles and register the rect data in a list.

Information about the registered image is saved in "skeleton2dhelper_save.txt" in the Godot project root directory.

If you want to create a mesh animation, divide the polygons.

Add the outline points roughly with the +.

After enclosing, finely arrange the outline points with the button that looks like a pencil mark.

To move, press the move button and the nearby point you clicked with the mouse will move.

It selects the closest point, so you don't need to professional FPS aim with the mouse!

After that, add internal points. The method is the same.
Internal points are displayed in blue.

If you hit them in a invalid place or the polygon becomes invalid, they won't be displayed, but moving the points and returning them to normal will fix it.

---

## Animation Tab

![image](https://github.com/user-attachments/assets/8ecca2da-ae9b-4558-9187-1c576d9f9bce)

under developping.
