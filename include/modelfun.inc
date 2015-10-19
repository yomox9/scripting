/*****************************************************************
 * ModelFun_PerformHat
 *
 * @client	Player id performing command
 * @target 	Target player id
 * @toggle 	Define toggle behaivour
 *			0 - enforce off
 *			1 - enforce on
 *			2 - toggle
 * @model	Model name to use as hat
 * @hatnow	Force hat to be activated now, defaults to true
 * @return bool true if operation succedded, otherwise false
 *****************************************************************/
native ModelFun_PerformHat( client, target, toggle, String:model[129], bool:hatnow=true );


/*****************************************************************
 * ModelFun_HatOff
 *
 * @client	Player id performing command
 * @target 	Target player id
 * @noreturn
 *****************************************************************/
native ModelFun_HatOff(client, target );

/*****************************************************************
 * ModelFun_PerformPHat
 *
 * @client	Player id performing command
 * @target 	Target player id
 * @toggle 	Define toggle behaivour
 *			0 - enforce off
 *			1 - enforce on
 *			2 - toggle
 * @particle	Particle name to use as hat
 * @hatnow	Force hat to be activated now, defaults to true
 * @return bool true if operation succedded, otherwise false
 *****************************************************************/
native ModelFun_PerformPHat( client, target, toggle, String:particle[129], bool:hatnow=true );


/*****************************************************************
 * ModelFun_PHatOff
 *
 * @client	Player id performing command
 * @target 	Target player id
 * @noreturn
 *****************************************************************/
native ModelFun_PHatOff(client, target );

public SharedPlugin:__pl_modelfun = 
{
	name = "Model Fun",
	file = "modelfun.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};


public __pl_ircrealy_SetNTVOptional()
{
	MarkNativeAsOptional("ModelFun_SetHatModel");
	MarkNativeAsOptional("ModelFun_PerformHat");
}
// Yarr
