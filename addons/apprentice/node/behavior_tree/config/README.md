行为树节点文档结构

```
|
  &
	?存在敌人
	>移动到位置
  &
	可以攻击到敌人时
	攻击敌人
  &
	徘徊

```

> `|` 代表 Selector，选择执行，有一个执行成功，则为true，重新开始执行，相当于 or
>
> `&` 代表 Sequence，顺序执行，全部执行成功，则为true，重新开始执行，相当于 and
>
> `?` 代表 Condition，执行条件，返回是否执行成功
>
> `>` 代表 Action，执行功能
>
> （ `?` 和 `>` 字符可以省略 ）
>



配置数据，以下为默认数据

```json
{
	"add_to_scene": true,
	"token": {
		"mean": [ // 开头字符所代表的含义，生成的节点结构所对应的类的类型
			{
				"name": "&", // & 代表下面的 Sequence 类，创建的时候创建这个类的节点
				"type": Sequence, // 这个值需要是 Class 或 Script 类型，且创建的类型为 Node 类型
			},
			{ "name": "|", "type": Selector },
			{ "name": "?", "type": Condition,
			 "init_prop": { "_callable": func(): return false }
			},
			{ "name": [">", ""], "type": Action,
			  "init_prop": { "_callable": func(): pass }
			}
		]
	},
	"objects": [
		"readable_name": false, // 具有可读性的节点名称
		"add_to_scene": true,	// 节点是否添加到场景中
		"do_method": [ // 优先以这种方式以指定的映射数据进行连接，没有则再以 callable_map_data 方式连接
			{
				"name": "移动到位置",   // 文档结构中的描述名称
				"type": BaseDoNode,  	// 创建的对象类型
				"method":  "do",	// String 或 Callable 类型，执行调用这个类型对象的方法，如果是字符串，则会自动创建 type 类型的对象并设置调用这个对象的方法，如果这个类是 Node 类型，则会自动添加到场景中
				"context": func(context: Dictionary):	// 上下文方法，解析完成创建对象后，调用这个方法，这个方法存储着整个结构，以及 root 和当前节点
					var node = context["node"]
					node.root = context["root"]
					,
				"init_prop": {  // 这个节点初始化设置属性
					"_callable": func(): return false,
				},
				
			}
		],		
		"match_node_list": [],	// 自动匹配节点中的方法名称，如果名称对应文档结构中的名称，且do_method中没有配置对象的方法名的数据，则自动设置为对应的执行方法
		
	]
}
```

> nodes，连接上面的生成的节点的信号，连接对应的方法
>
> custom.token.mean 中的 name 列表，或在初始化时，变为单个的 Dictionary 汇总的值，所以如果有多个相同的 name 值，则会覆盖掉之前的值
