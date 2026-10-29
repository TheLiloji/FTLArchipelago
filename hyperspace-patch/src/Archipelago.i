
%{
#include "Archipelago.h"
%}

%rename("%s") ArchipelagoFTL;

%rename("ArchipelagoEvent") ArchipelagoFTL::Event;
%rename("%s") ArchipelagoFTL::Event::kind;
%rename("%s") ArchipelagoFTL::Event::name;
%rename("%s") ArchipelagoFTL::Event::sender;
%rename("%s") ArchipelagoFTL::Event::extra;
%rename("%s") ArchipelagoFTL::Event::other;
%rename("%s") ArchipelagoFTL::Event::value;
%rename("%s") ArchipelagoFTL::Event::index;

%nodefaultctor ArchipelagoFTL::Client;
%nodefaultdtor ArchipelagoFTL::Client;
%rename("ArchipelagoClient") ArchipelagoFTL::Client;
%rename("%s") ArchipelagoFTL::Client::Connect;
%rename("%s") ArchipelagoFTL::Client::Disconnect;
%rename("%s") ArchipelagoFTL::Client::IsConnected;
%rename("%s") ArchipelagoFTL::Client::TakeEvents;
%rename("%s") ArchipelagoFTL::Client::SendCheck;
%rename("%s") ArchipelagoFTL::Client::ScoutLocations;
%rename("%s") ArchipelagoFTL::Client::HintLocation;
%rename("%s") ArchipelagoFTL::Client::SendGoal;
%rename("%s") ArchipelagoFTL::Client::SendDeath;
%rename("%s") ArchipelagoFTL::Client::SendTrap;
%rename("%s") ArchipelagoFTL::Client::AnnounceTrapLink;
%rename("%s") ArchipelagoFTL::Client::EnergyDeposit;
%rename("%s") ArchipelagoFTL::Client::EnergyRequest;
%rename("%s") ArchipelagoFTL::Client::Say;
%rename("%s") ArchipelagoFTL::Client::SetTags;
%rename("%s") ArchipelagoFTL::Client::PlayerName;
%rename("%s") ArchipelagoFTL::Client::CheckedLocations;
%rename("%s") ArchipelagoFTL::Client::LastUri;
%rename("%s") ArchipelagoFTL::Client::LastSlot;
%rename("%s") ArchipelagoFTL::Client::Clipboard;
%rename("%s") ArchipelagoFTL::Client::Platform;
%rename("%s") ArchipelagoFTL::Client::RequestProfileReset;
%rename("%s") ArchipelagoFTL::Client::RelaunchWhenClosed;
%rename("%s") ArchipelagoFTL::Client::ProfileResetRequested;
%rename("%s") ArchipelagoFTL::Client::ProfileId;
%rename("%s") ArchipelagoFTL::Client::ProfileIds;
%rename("%s") ArchipelagoFTL::Client::SwitchProfile;
%rename("%s") ArchipelagoFTL::Client::PendingProfile;
%rename("%s") ArchipelagoFTL::Client::ArchiveProfile;
%rename("%s") ArchipelagoFTL::Client::DescribeProfile;
%rename("%s") ArchipelagoFTL::Client::ProfileDetail;
%rename("%s") ArchipelagoFTL::Client::RememberState;
%rename("%s") ArchipelagoFTL::Client::RecallState;
%rename("%s") ArchipelagoFTL::Client::SetShipLock;
%rename("%s") ArchipelagoFTL::Client::UnlockShip;
%rename("%s") ArchipelagoFTL::Client::LockShips;
%rename("%s") ArchipelagoFTL::Client::AchievementStatus;
%rename("%s") ArchipelagoFTL::Client::HideBeaconLabel;
%rename("%s") ArchipelagoFTL::Client::SetGame;

%immutable MainMenu::bScoreScreen;
%rename("%s") MainMenu::bScoreScreen;
%immutable MainMenu::bCreditScreen;
%rename("%s") MainMenu::bCreditScreen;
%immutable MainMenu::bSelectSave;
%rename("%s") MainMenu::bSelectSave;
%immutable MainMenu::optionScreen;
%rename("%s") MainMenu::optionScreen;
%nodefaultctor OptionsScreen;
%nodefaultdtor OptionsScreen;
%rename("%s") OptionsScreen;

%nodefaultctor ArchipelagoFTL::Archipelago;
%nodefaultdtor ArchipelagoFTL::Archipelago;
%rename("%s") ArchipelagoFTL::Archipelago;
%rename("%s") ArchipelagoFTL::Archipelago::Instance;

%include "Archipelago.h"

namespace std {
    %template(vector_ArchipelagoEvent) vector<ArchipelagoFTL::Event>;
}
